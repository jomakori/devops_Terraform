# Google OAuth identity provider for CF Access
resource "cloudflare_zero_trust_access_identity_provider" "google_oauth" {
  account_id = var.CLOUDFLARE_ACCOUNT_ID
  name       = "Google OAuth"
  type       = "google"
  config = {
    client_id     = var.GOOGLE_OAUTH_CLIENT_ID
    client_secret = var.GOOGLE_OAUTH_CLIENT_SECRET
  }
}

# Per-host Access Applications + policy using Google OAuth.
# Live state has per-host apps only: grafana, excalidash, openagent, plus the
# wildcard app covering the OpenKite PR preview hosts.

# Grafana — grafana.maklab.net
resource "cloudflare_zero_trust_access_application" "grafana_private" {
  account_id       = var.CLOUDFLARE_ACCOUNT_ID
  name             = "grafana-private"
  type             = "self_hosted"
  session_duration = "24h"
  domain           = "grafana.${var.gitops_config["clusterDomain"]}"
  allowed_idps     = [cloudflare_zero_trust_access_identity_provider.google_oauth.id]

  policies = [{
    name     = "allow-google-auth"
    decision = "allow"
    include  = [{ everyone = {} }]
  }]
}

# OpenAgent — openagent.maklab.net
resource "cloudflare_zero_trust_access_application" "openagent_private" {
  account_id       = var.CLOUDFLARE_ACCOUNT_ID
  name             = "openagent-private"
  type             = "self_hosted"
  session_duration = "24h"
  domain           = "openagent.${var.gitops_config["clusterDomain"]}"
  allowed_idps     = [cloudflare_zero_trust_access_identity_provider.google_oauth.id]

  policies = [{
    name     = "allow-google-auth"
    decision = "allow"
    include  = [{ everyone = {} }]
  }]
}

# ExcaliDash — draw.maklab.net
resource "cloudflare_zero_trust_access_application" "excalidash_private" {
  account_id       = var.CLOUDFLARE_ACCOUNT_ID
  name             = "excalidash-private"
  type             = "self_hosted"
  session_duration = "24h"
  domain           = "draw.${var.gitops_config["clusterDomain"]}"
  allowed_idps     = [cloudflare_zero_trust_access_identity_provider.google_oauth.id]

  policies = [{
    name     = "allow-google-auth"
    decision = "allow"
    include  = [{ everyone = {} }]
  }]
}

# ── OpenKite — openkite.maklab.net ───────────────────────────────────────────
# The production console. The workload spec in gke_GitOps sets `enable_private`, so
# the mesh already denies anything without a valid Access JWT for this exact host;
# this application is the other half of that gate — the one that ISSUES the JWT. A
# host missing from either layer dies at the layer it is missing from: no Cloudflare
# challenge means no JWT, which the gateway answers with `403`.
resource "cloudflare_zero_trust_access_application" "openkite_private" {
  account_id       = var.CLOUDFLARE_ACCOUNT_ID
  name             = "openkite-private"
  type             = "self_hosted"
  session_duration = "24h"
  domain           = "openkite.${var.gitops_config["clusterDomain"]}"
  allowed_idps     = [cloudflare_zero_trust_access_identity_provider.google_oauth.id]

  policies = [{
    name     = "allow-google-auth"
    decision = "allow"
    include  = [{ everyone = {} }]
  }]
}

# Push each app AUD to Doppler so the gitops appset adds them to the istio
# RequestAuthentication (cf-access-jwt) audiences list.
resource "doppler_secret" "cf_access_aud_excalidash" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "CF_ACCESS_AUD_EXCALIDASH"
  value   = cloudflare_zero_trust_access_application.excalidash_private.aud
}

resource "doppler_secret" "cf_access_aud_grafana" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "CF_ACCESS_AUD_GRAFANA"
  value   = cloudflare_zero_trust_access_application.grafana_private.aud
}

resource "doppler_secret" "cf_access_aud_openagent" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "CF_ACCESS_AUD_OPENAGENT"
  value   = cloudflare_zero_trust_access_application.openagent_private.aud
}

resource "doppler_secret" "cf_access_aud_openkite" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "CF_ACCESS_AUD_OPENKITE"
  value   = cloudflare_zero_trust_access_application.openkite_private.aud
}

# ── OpenKite PR previews — pr<N>.maklab.net ─────────────────────────────────
# One wildcard app, not one app per PR: preview hostnames are generated (one per
# open PR that published an image) and churn continuously, so there is nothing
# static to enumerate here.
#
# `pr<N>.maklab.net` — the PR id IS the label, and there is no `openkite` in the
# host. That shape is what makes this gate expressible at all: Cloudflare Access
# allows one wildcard per label, so `pr*` matches every preview host with a single
# application. It is also the only affordable shape — the host is one label under
# the zone, which Universal SSL covers; a two-level host (`pr-<N>.openkite.…`)
# gets no edge certificate at all (Total TLS skips Tunnel hostnames), so it would
# fail the handshake before it ever reached this application.
#
# The second layer of the gate is Istio's DENY policy, rendered per preview by the
# `openkite` spec in gke_GitOps/apps/helm (see its `enable_private`). It cannot be
# a wildcard: istio matches a policy's hosts by exact value or a leading `*.`
# SUFFIX, so `pr*.maklab.net` has no single-policy form and every preview gets one
# exact-host policy instead. A host missing from either layer dies at the layer it
# is missing from: no CF challenge ⇒ no JWT ⇒ `403` at the gateway.
#
# A wildcard never covers its parent, so this does NOT protect `openkite.maklab.net`
# (the application above does), nor a deeper host such as `a.pr1.maklab.net`.
resource "cloudflare_zero_trust_access_application" "openkite_previews_private" {
  account_id       = var.CLOUDFLARE_ACCOUNT_ID
  name             = "openkite-previews-private"
  type             = "self_hosted"
  session_duration = "24h"
  domain           = "pr*.${var.gitops_config["clusterDomain"]}"
  allowed_idps     = [cloudflare_zero_trust_access_identity_provider.google_oauth.id]

  policies = [{
    name     = "allow-google-auth"
    decision = "allow"
    include  = [{ everyone = {} }]
  }]
}

# AUD of the wildcard preview app. Istio's RequestAuthentication accepts only
# the audiences in `ACCESS_AUDIENCE_TAG` (Doppler devops/ci), and that list is
# assembled by hand from the per-app keys below, so a new app is not gated
# end-to-end until this aud is appended to it. The aud only exists after the
# app is created, which is why the aggregation cannot live in this file:
#   1. apply -> app created, aud known
#   2. doppler secrets set CF_ACCESS_AUDS="<current list>,<new aud>" \
#        -p devops -c svc_cloudflare          # the list istio consumes
#   3. doppler secrets set TF_VAR_ACCESS_AUDIENCE_TAG="<same list>" -p devops -c ci
#   4. sync the `services` Application -> istio re-renders the
#      RequestAuthentication with grown audiences. Both AUDs this file adds
#      (CF_ACCESS_AUD_OPENKITE, CF_ACCESS_AUD_OPENKITE_PREVIEWS) have to be in
#      that list, or the login succeeds and the gateway still answers `403`.
# Until step 4 an authenticated browser still gets `403` — the login succeeds,
# the JWT's aud is simply not accepted yet.
resource "doppler_secret" "cf_access_aud_openkite_previews" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "CF_ACCESS_AUD_OPENKITE_PREVIEWS"
  value   = cloudflare_zero_trust_access_application.openkite_previews_private.aud
}

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
# The mesh half of this gate is the app spec's enable_private; this issues the JWT.
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

# ── OpenKite PR previews — pr<N>-openkite.maklab.net ─────────────────────────────────
# One wildcard app: preview hosts are generated per PR and churn. The app name is
# in the label, so the wildcard matches only this app's previews.
# Istio cannot mirror the wildcard (policy hosts match exact or leading `*.`), so
# each preview carries its own exact-host DENY policy instead.
# A wildcard never covers its parent: openkite.maklab.net has the app above.
resource "cloudflare_zero_trust_access_application" "openkite_previews_private" {
  account_id       = var.CLOUDFLARE_ACCOUNT_ID
  name             = "openkite-previews-private"
  type             = "self_hosted"
  session_duration = "24h"
  domain           = "pr*-openkite.${var.gitops_config["clusterDomain"]}"
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
#      RequestAuthentication with grown audiences. Both auds added here must be in
#      that list, or the login succeeds and the gateway still answers `403`.
# Until step 4 an authenticated browser still gets `403` — the login succeeds,
# the JWT's aud is simply not accepted yet.
resource "doppler_secret" "cf_access_aud_openkite_previews" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "CF_ACCESS_AUD_OPENKITE_PREVIEWS"
  value   = cloudflare_zero_trust_access_application.openkite_previews_private.aud
}

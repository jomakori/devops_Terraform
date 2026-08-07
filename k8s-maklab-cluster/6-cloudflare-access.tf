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
# (Wildcard *.maklab.net app removed — live state is per-host apps only:
#  grafana-private, onedev-private, openagent-private, + excalidash-private.)

# ExcaliDash — draw.maklab.net
resource "cloudflare_zero_trust_access_application" "excalidash_private" {
  account_id         = var.CLOUDFLARE_ACCOUNT_ID
  name               = "excalidash-private"
  type               = "self_hosted"
  session_duration   = "24h"
  domain             = "draw.${var.gitops_config["clusterDomain"]}"
  allowed_idps       = [cloudflare_zero_trust_access_identity_provider.google_oauth.id]

  policies = [{
    name     = "allow-google-auth"
    decision = "allow"
    include  = [{ everyone = {} }]
  }]
}

# Push AUD to Doppler so the gitops appset can add it to the istio
# RequestAuthentication (cf-access-jwt) audiences list.
resource "doppler_secret" "cf_access_aud_excalidash" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "CF_ACCESS_AUD_EXCALIDASH"
  value   = cloudflare_zero_trust_access_application.excalidash_private.aud
}

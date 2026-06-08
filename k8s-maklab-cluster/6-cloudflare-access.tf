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

# Access Application + policy using Google OAuth
resource "cloudflare_zero_trust_access_application" "maklab_private" {
  account_id         = var.CLOUDFLARE_ACCOUNT_ID
  name               = "maklab-private"
  type               = "self_hosted"
  session_duration   = "24h"
  domain             = "*.${var.gitops_config["clusterDomain"]}"
  allowed_idps       = [cloudflare_zero_trust_access_identity_provider.google_oauth.id]

  policies = [{
    name     = "allow-google-auth"
    decision = "allow"
    include  = [{ everyone = {} }]
  }]
}

# Push AUD to Doppler so Istio can reference it for JWT validation
resource "doppler_secret" "cf_access_aud" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "CF_ACCESS_AUD"
  value   = cloudflare_zero_trust_access_application.maklab_private.aud
}

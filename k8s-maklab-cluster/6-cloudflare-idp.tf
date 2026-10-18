# Google OAuth identity provider for CF Access.
#
# Only the account-level IdP stays in Terraform. The per-host Access
# applications, their policies and the Doppler AUD secrets moved to the GitOps
# repo (Crossplane, `cloudflareaccessapps.platform.maklab.net`): a service opts
# in with `gateways.enable_private: true` next to the VirtualService it gates.
#
# The IdP has to outlive the applications: an app with no allowed_idps uses the
# account default, so destroying this would leave every Access app unauthenticated.
resource "cloudflare_zero_trust_access_identity_provider" "google_oauth" {
  account_id = var.CLOUDFLARE_ACCOUNT_ID
  name       = "Google OAuth"
  type       = "google"
  config = {
    client_id     = var.GOOGLE_OAUTH_CLIENT_ID
    client_secret = var.GOOGLE_OAUTH_CLIENT_SECRET
  }
}

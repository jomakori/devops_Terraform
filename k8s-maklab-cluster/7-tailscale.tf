/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Tailscale Kubernetes Operator credentials                                │
  └──────────────────────────────────────────────────────────────────────────┘
 */
# OAuth client creds for the Tailscale k8s operator (services/helm/tailscale).
# The operator mounts Secret operator-oauth (files client_id/client_secret),
# pre-created by an ExternalSecret backed by this Doppler config.
resource "doppler_config" "svc_tailscale" {
  project     = var.tunnel_config["doppler_project"]
  name        = "svc_tailscale"
  environment = "svc"
}

resource "doppler_secret" "tailscale_oauth_client_id" {
  project = var.tunnel_config["doppler_project"]
  config  = doppler_config.svc_tailscale.name
  name    = "TAILSCALE_OAUTH_CLIENT_ID"
  value   = var.TAILSCALE_OAUTH_CLIENT_ID
}

resource "doppler_secret" "tailscale_oauth_client_secret" {
  project = var.tunnel_config["doppler_project"]
  config  = doppler_config.svc_tailscale.name
  name    = "TAILSCALE_OAUTH_CLIENT_SECRET"
  value   = var.TAILSCALE_OAUTH_CLIENT_SECRET
}

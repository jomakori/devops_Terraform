/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Tailscale Kubernetes Operator credentials                                │
  └──────────────────────────────────────────────────────────────────────────┘
 */
# OAuth client for the Tailscale k8s operator — created + managed by Terraform.
# (Requires the Tailscale API key to have api_key:write scope.)
# The operator assigns tag:k8s-operator to itself and tag:k8s to proxy devices,
# so the client must own both tags.
resource "tailscale_oauth_client" "k8s_operator" {
  description = "Tailscale Kubernetes Operator"
  scopes      = ["devices:core"]
  tags        = ["tag:k8s-operator", "tag:k8s"]
}

# Doppler config consumed by the operator's ExternalSecret (doppler-svc-tailscale)
resource "doppler_config" "svc_tailscale" {
  project     = var.tunnel_config["doppler_project"]
  name        = "svc_tailscale"
  environment = "svc"
}

resource "doppler_secret" "tailscale_oauth_client_id" {
  project = var.tunnel_config["doppler_project"]
  config  = doppler_config.svc_tailscale.name
  name    = "TAILSCALE_OAUTH_CLIENT_ID"
  value   = tailscale_oauth_client.k8s_operator.id
}

resource "doppler_secret" "tailscale_oauth_client_secret" {
  project = var.tunnel_config["doppler_project"]
  config  = doppler_config.svc_tailscale.name
  name    = "TAILSCALE_OAUTH_CLIENT_SECRET"
  value   = tailscale_oauth_client.k8s_operator.key
}

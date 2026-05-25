# ── init ──
resource "random_id" "tunnel_secret" {
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "maklab" {
  account_id    = var.CLOUDFLARE_ACCOUNT_ID
  name          = var.tunnel_config["tunnel_name"]
  tunnel_secret = base64encode(random_id.tunnel_secret.hex)
  config_src    = "cloudflare"

  depends_on = [kubectl_manifest.services]
}

# ── Ingress ──
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "maklab" {
  account_id = var.CLOUDFLARE_ACCOUNT_ID
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.maklab.id

  config = {
    ingress = [{
      hostname = "*.${var.gitops_config["clusterDomain"]}"
      service  = "https://istio-ingressgateway.istio-system.svc:443"
      origin_request = {
        no_tls_verify     = true
        match_sn_ito_host = true
      }
    },
    {
      service = "http_status:404"
    }]
  }
}

# ── Token ──
data "cloudflare_zero_trust_tunnel_cloudflared_token" "maklab" {
  account_id = var.CLOUDFLARE_ACCOUNT_ID
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.maklab.id
}

# ── Secrets ──
resource "doppler_secret" "tunnel_token" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "TUNNEL_TOKEN"
  value   = data.cloudflare_zero_trust_tunnel_cloudflared_token.maklab.token
}

resource "doppler_secret" "tunnel_id" {
  project = var.tunnel_config["doppler_project"]
  config  = var.tunnel_config["doppler_config"]
  name    = "TUNNEL_ID"
  value   = cloudflare_zero_trust_tunnel_cloudflared.maklab.id
}

# ── DNS ──
resource "cloudflare_dns_record" "wildcard_maklab" {
  zone_id = data.cloudflare_zone.maklab.zone_id
  name    = "*.${var.gitops_config["clusterDomain"]}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.maklab.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

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

# ── R2 backups (StackGres pg-main) ─────────────────────────────────────────
# Bucket + S3-compatible creds pushed to Doppler svc_postgres_operator for the
# pg-main SGCluster's SGObjectStorage (weekly base + WAL archiving).
# Creds come from TF_VAR_R2_* (Cloudflare dashboard → R2 → Manage API tokens).
resource "cloudflare_r2_bucket" "pg_main" {
  account_id = var.CLOUDFLARE_ACCOUNT_ID
  name       = "stackgres-pg-main"
  location   = "WNAM"
}

resource "doppler_secret" "r2_access_key_id" {
  project = "devops"
  config  = "svc_postgres_operator"
  name    = "R2_ACCESS_KEY_ID"
  value   = var.R2_ACCESS_KEY_ID
}

resource "doppler_secret" "r2_secret_access_key" {
  project = "devops"
  config  = "svc_postgres_operator"
  name    = "R2_SECRET_ACCESS_KEY"
  value   = var.R2_SECRET_ACCESS_KEY
}

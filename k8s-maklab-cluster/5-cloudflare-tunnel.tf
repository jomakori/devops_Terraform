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
        match_sni_to_host = true
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

# 2-level wildcard for PR previews: pr-<N>.openkite.maklab.net. Cloudflare
# wildcard DNS is multi-level, so *.maklab.net already resolves this host; this
# explicit record declares Terraform the owner and takes precedence over it.
resource "cloudflare_dns_record" "wildcard_openkite" {
  zone_id = data.cloudflare_zone.maklab.zone_id
  name    = "*.openkite.${var.gitops_config["clusterDomain"]}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.maklab.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

# ── Edge certificate for the preview hosts ─────────────────────────────────
# `pr-<N>.openkite.maklab.net` is served no certificate at all today, so the TLS
# handshake dies before Cloudflare's application layer and no Access policy can
# ever run for a preview host (`curl https://pr-134.openkite.maklab.net` →
# `ssl/tls alert handshake failure`, while the one-level `openagent.maklab.net`
# answers `302` to the Access login). Two Cloudflare rules produce that:
# Universal SSL covers the zone apex and one level of subdomain only, and Total
# TLS does not issue certificates for hostnames served through Cloudflare Tunnel.
# This orders the certificate that covers the preview wildcard.
#
# Not applied automatically: ordering an advanced certificate needs the Advanced
# Certificate Manager add-on on the zone (a purchase made in the dashboard, not a
# resource) and an API token carrying `SSL and Certificates: Read + Write` — the
# current token answers `9109 Unauthorized` on the certificate_packs endpoint.
#
# The API requires the zone apex among the hosts, so it is listed next to the
# preview wildcard. Cloudflare serves the most specific certificate matching a
# hostname, so the apex and the one-level hosts keep the coverage they have.
resource "cloudflare_certificate_pack" "openkite_previews" {
  zone_id               = data.cloudflare_zone.maklab.zone_id
  type                  = "advanced"
  certificate_authority = "lets_encrypt"
  validation_method     = "txt"
  validity_days         = 90
  cloudflare_branding   = false
  hosts = [
    var.gitops_config["clusterDomain"],
    "*.openkite.${var.gitops_config["clusterDomain"]}",
  ]
}

# ── R2 backups (StackGres pg-main) ─────────────────────────────────────────
# Bucket + S3-compatible creds pushed to Doppler svc_postgres_operator for the
# pg-main SGCluster's SGObjectStorage (weekly base + WAL archiving).
# Creds come from TF_VAR_R2_* (Cloudflare dashboard → R2 → Manage API tokens).
# Managed by the AWS provider against R2's S3 endpoint (see versions.tf) -
# `cloudflare_r2_bucket` would require the R2 permission scope on an API token
# this workspace shares with everything else, while the S3 path uses the R2
# credentials it already has.
# The bucket was created out-of-band on 2026-08-20, so it is imported rather
# than created. Terraform can drop the block once it has been applied.
# The R2 location hint (WNAM) is not expressible over the S3 API; the bucket
# already exists with it set.
import {
  to = aws_s3_bucket.pg_main
  id = "stackgres-pg-main"
}

resource "aws_s3_bucket" "pg_main" {
  bucket = "stackgres-pg-main"
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

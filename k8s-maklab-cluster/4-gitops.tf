locals {
  gitops = merge(var.gitops_config, {
    clusterName       = var.cluster_config["name"]
    accessTeamDomain  = var.ACCESS_TEAM_DOMAIN
    accessAudienceTag = var.ACCESS_AUDIENCE_TAG
  })
}

resource "kubectl_manifest" "services" {
  yaml_body = templatefile("${path.module}/argocd_app-of-apps/services.yml",
    merge(local.gitops, { path = local.gitops["services_path"] })
  )
  force_new  = true
  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "apps" {
  yaml_body = templatefile("${path.module}/argocd_app-of-apps/apps.yml",
    merge(local.gitops, { path = local.gitops["apps_path"] })
  )
  force_new  = true
  depends_on = [kubectl_manifest.services]
}

# ── Trusted proxy IPs for OpenClaw Gateway ──
# OpenClaw uses trusted-proxy auth (CF Access → Istio Gateway → OpenClaw).
# The gateway only trusts connections from these IPs.
data "kubernetes_nodes" "all" {}

locals {
  trusted_proxy_ips = jsonencode(flatten([
    for node in data.kubernetes_nodes.all.nodes : [
      for addr in node.status[0].addresses : addr.address
      if addr.type == "InternalIP"
    ]
  ]))
}

# Re-declared during drift reconciliation: the webhook is live (id 654770250)
# and was dropped from config — without this it would be destroyed on apply.
data "doppler_secrets" "svc_argocd" {
  project = var.tunnel_config["doppler_project"]
  config  = "svc_argocd"
}

resource "github_repository_webhook" "argocd" {
  repository = "gke_GitOps"
  events     = ["push"]
  configuration {
    url          = "https://argocd.maklab.net/api/webhook"
    content_type = "json"
    insecure_ssl = false
    # Read the existing secret back from Doppler so it stays stable.
    secret = data.doppler_secrets.svc_argocd.map["WEBHOOK_GITHUB_SECRET"]
  }
  depends_on = [helm_release.argocd]
}

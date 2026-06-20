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

# resource "kubectl_manifest" "apps" {
#   yaml_body = templatefile("${path.module}/argocd_app-of-apps/apps.yml",
#     merge(local.gitops, { path = local.gitops["apps_path"] })
#   )
#   force_new  = true
#   depends_on = [kubectl_manifest.services]
# }

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

resource "doppler_secret" "trusted_proxy_ips" {
  project = "devops"
  config  = "svc_openclaw"
  name    = "TRUSTED_PROXY_IPS"
  value   = local.trusted_proxy_ips
}

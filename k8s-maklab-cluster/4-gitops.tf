locals {
  gitops = merge(var.gitops_config, { clusterName = var.cluster_config["name"] })
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

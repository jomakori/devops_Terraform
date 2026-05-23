# GitOps: App of Apps Deployment
resource "kubectl_manifest" "services" {
  yaml_body = templatefile("${path.module}/argocd_app-of-apps/services.yml",
    {
      gitops_repo          = var.gitops_repo
      gitops_services_path = var.gitops_services_path
      gitops_branch        = var.gitops_branch

      # cluster values
      cluster_name     = var.name
      cluster_endpoint = "localhost"

  })

  force_new  = true # re-create on changes
  depends_on = [helm_release.argocd]
}


# resource "kubectl_manifest" "apps" {
#   yaml_body = templatefile("${path.module}/argocd_app-of-apps/apps.yml",
#     {
#       gitops_repo      = var.gitops_repo
#       gitops_apps_path = var.gitops_apps_path
#       gitops_branch    = var.gitops_branch

#       # Passing doppler tokens to deployments
#       doppler_notes_app_prod    = var.DOPPLER_PROD_TOKEN
#       doppler_notes_app_staging = var.DOPPLER_STAGING_TOKEN
#   })

#   force_new  = true                        # re-create on changes
#   depends_on = [kubectl_manifest.services] # see gitops_deps.tf
# }

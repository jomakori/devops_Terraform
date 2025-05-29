###########################################################################################################
# ----------------------------------- GitOps: App of Apps Deployment ------------------------------------ #
# ------------------------------------------------------------------------------------------------------- #
# ----------------------------------------------IMPORTANT:----------------------------------------------- #
# ------------------ USE THE HELM TEMPLATE STRUCTURE WHEN ADDING NEW APPS/SERVICES ---------------------- #
# WE PASS IN DYNAMIC VARS THAT WILL LATER BE PASSED TO THE DEPLOYMENTS OF APPS/SERVICES (SEE GITOPS REPO) #
# ------------------------------------------------------------------------------------------------------- #
# ------ Manifests that are outside the helm deployment can be placed in the provisioners folder -------- #
# ------------------- See gitops_deps.tf for more info on manual manifest deployment -------------------- #
###########################################################################################################
resource "kubectl_manifest" "services" {
  yaml_body = templatefile("${path.module}/argocd_app-of-apps/services.yml",
    {
      gitops_repo          = var.gitops_repo
      gitops_services_path = var.gitops_services_path
      gitops_branch        = var.gitops_branch

      # GCP values
      gcp_region           = var.region
      gcp_account          = var.project_id
      gcp_cluster_name     = var.name
      gcp_cluster_endpoint = "localhost"
      # service values to pass into helm charts
      grafana_admin = var.GRAFANA_ADMIN
      grafana_pw    = var.GRAFANA_PW
      pg_user       = var.PG_USER
      pg_pw         = var.PG_PW
  })
  force_new  = true # re-create on changes
  depends_on = [helm_release.argocd]
}


resource "kubectl_manifest" "apps" {
  yaml_body = templatefile("${path.module}/argocd_app-of-apps/apps.yml",
    {
      gitops_repo      = var.gitops_repo
      gitops_apps_path = var.gitops_apps_path
      gitops_branch    = var.gitops_branch

      # Passing doppler tokens to deployments
      doppler_notes_app_prod    = var.DOPPLER_PROD_TOKEN
      doppler_notes_app_staging = var.DOPPLER_STAGING_TOKEN
  })

  force_new  = true                        # re-create on changes
  depends_on = [kubectl_manifest.services] # see gitops_deps.tf
}

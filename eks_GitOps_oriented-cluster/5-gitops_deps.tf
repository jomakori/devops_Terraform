############################################
# SETUP PRIVATE GIT REPO ACCESS FOR ARGOCD #
############################################
resource "kubernetes_secret" "private_repo_access" {
  metadata {
    name      = "private-repo-access"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    url      = var.gitops_repo
    password = var.GITHUB_TOKEN
    username = "not-used"
  }
  depends_on = [helm_release.argocd]
}
###########################################################################################
# ------------------------- PROVISIONER MANIFESTS FOR SERVICES -------------------------- #
# ---- Note: This deploys manifests that can't be deployed via Helm Chart --------------- #
###########################################################################################
resource "kubectl_manifest" "service_provisioners" {
  for_each = fileset("${path.module}/provisioners", "*.yml")

  yaml_body = templatefile("${path.module}/provisioners/${each.value}",
    {
      KARPENTER_NODE_ROLE   = module.eks_blueprints_addons.karpenter.node_iam_role_name
      KARPENTER_PROVISIONER = lower("${var.name}-autoscaler") # due to case-sensitivity
      CLUSTER_NAME          = "${var.name}-cluster"
      GH_ORG                = "richcontext"
      DD_API_KEY            = var.DD_API_KEY
      DD_APP_KEY            = var.DD_APP_KEY
  })

  force_new  = false # always confirm changes in cluster
  depends_on = [kubectl_manifest.services]
}

# Prisma TwistLock Defender setup - ISD requirement
resource "kubectl_manifest" "prisma_provisioners" {
  for_each = fileset("${path.module}/provisioners/prisma-defender", "*.yml")

  yaml_body = templatefile("${path.module}/provisioners/prisma-defender/${each.value}",
    {
      PRISMA_TWISTLOCK_SERVICE_PARAMETER    = var.PRISMA_TWISTLOCK_SERVICE_PARAMETER
      PRISMA_TWISTLOCK_DEFENDER_CA          = var.PRISMA_TWISTLOCK_DEFENDER_CA
      PRISMA_TWISTLOCK_DEFENDER_CLIENT_CERT = var.PRISMA_TWISTLOCK_DEFENDER_CLIENT_CERT
      PRISMA_TWISTLOCK_DEFENDER_CLIENT_KEY  = var.PRISMA_TWISTLOCK_DEFENDER_CLIENT_KEY
      PRISMA_TWISTLOCK_ADMISSION_CERT       = var.PRISMA_TWISTLOCK_ADMISSION_CERT
      PRISMA_TWISTLOCK_ADMISSION_KEY        = var.PRISMA_TWISTLOCK_ADMISSION_KEY
  })

  force_new  = false # always confirm changes in cluster
  depends_on = [kubectl_manifest.services]
}

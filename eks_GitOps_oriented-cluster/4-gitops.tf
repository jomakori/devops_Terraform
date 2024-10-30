#----------------------------------------------------------------------------------------------------------------------#
#----------------------------------------------- EKS BLUEPRINTS ADDONS ------------------------------------------------#
#---------- PURPOSE: CREATES THE DEPENDENT COMPONENTS LIKE IRSA ACCOUNTS, ETC FOR THE SERVICES DEPLOYMENT -------------#
#----------------------------------------------------------------------------------------------------------------------#
module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.eks_cluster_id
  cluster_endpoint  = module.eks.eks_cluster_endpoint
  cluster_version   = module.eks.eks_cluster_version
  oidc_provider_arn = module.eks.eks_cluster_identity_oidc_issuer_arn

  #------------------------------------------------------------------------------------------------------------------------#
  #------------------------------------------------- IRSA Configuration ---------------------------------------------------#
  #------------------------------------------------------------------------------------------------------------------------#

  # AWS Console-Managed plugins
  ## Note: Access permissions for these addons are managed via the node group role
  ### See EKS Node Group Module for more info - (3-eks.tf file)
  eks_addons = {
    coredns = {
      most_recent = true
    },
    kube-proxy = {
      most_recent = true
    },
    vpc-cni = {
      most_recent = true
    },
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
  #---------------------------------------------------------#
  #----------- ArgoCD GitOps-managed AWS services ----------#
  #---------------------------------------------------------#
  enable_external_secrets             = true
  enable_aws_load_balancer_controller = true
  enable_karpenter                    = true
  ## Custom Karpenter properties ##
  karpenter_enable_spot_termination          = true
  karpenter_enable_instance_profile_creation = true
  karpenter_node = {
    iam_role_use_name_prefix = false
  }
  #---------------------------------------------------------#
  #-------- ArgoCD GitOps-managed 3rd-party services -------#
  #---------------------------------------------------------#
  enable_metrics_server = true

  tags = var.tags
}

#####################################################################
# ------------------------- SETUP ARGOCD -------------------------- #
# ----- Used for syncing Apps + Services from the GitOps repo ----- #
# -------- Repo: https://github.com/richcontext/kubernetes -------- #
#####################################################################
resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true

  name       = "argo-cd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  # version    = "6.*" # Grab latest version of ArgoCD

  values = [templatefile("${path.module}/argocd-values.yaml", {
    DOMAIN = "argocd.intrc.net"
    # Github SSO secrets
    SSO_APP_ID     = var.ARGOCD_GH_SSO_APPID
    SSO_APP_SECRET = var.ARGOCD_GH_SSO_SECRET
    GH_ORG         = "richcontext"
    # Slack secret
    SLACK_NOTIFY_TOKEN = var.SLACK_ENOTIFY_TOKEN
  })]

  depends_on = [module.eks_blueprints_addons] # see gitops_deps.tf
}

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
      # AWS values
      aws-region           = var.region
      aws-account          = data.aws_caller_identity.current.account_id
      aws-cluster_name     = module.eks.eks_cluster_id
      aws-cluster_endpoint = module.eks.eks_cluster_endpoint
      # service values from eks_blueprints_addons values
      awsloadbalancercontroller-sa = jsondecode(module.eks_blueprints_addons.aws_load_balancer_controller.values).serviceAccount.name
      externalsecrets-sa           = jsondecode(module.eks_blueprints_addons.external_secrets.values).serviceAccount.name
      karpenter-sa                 = jsondecode(module.eks_blueprints_addons.karpenter.values).serviceAccount.name
      karpenter-sqs_queue          = module.eks_blueprints_addons.karpenter.sqs.queue_name
      # custom service values (outside eks_blueprints_addons scope)
      REDIS_PW                  = var.REDIS_PW
      DB_TUNNEL_PROD_DB_HOST    = var.PROD_DB_HOST
      DB_TUNNEL_STAGING_DB_HOST = var.STAGING_DB_HOST
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
      doppler_demo_app_prod    = var.DOPPLER_PROD_TOKEN
      doppler_demo_app_staging = var.DOPPLER_STAGING_TOKEN
      doppler_retailer_prod    = var.DOPPLER_RETAILER_PROD
  })

  force_new  = true                                    # re-create on changes
  depends_on = [kubectl_manifest.service_provisioners] # see gitops_deps.tf
}

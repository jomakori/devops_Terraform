###############################################################################################
#------------------------------------ Provider Versioning ------------------------------------# 
###############################################################################################
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

############################################################################################
#------------------------------------ Provider Configs ------------------------------------# 
############################################################################################

# Google Cloud
provider "google" {
  project = "absolute-cipher-449014-p0"
  region  = "us-central1"
}
data "google_compute_zones" "available" {
  provider = google
}
# data "google_client_config" "default" {}

# provider "kubernetes" {
#   host                   = "https://${module.gke.endpoint}"
#   token                  = data.google_client_config.default.access_token
#   cluster_ca_certificate = base64decode(module.gke.ca_certificate)
# }


# provider "helm" {
#   kubernetes {
#     host                   = module.eks.eks_cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.eks_cluster_certificate_authority_data)

#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       # This requires the awscli to be installed locally where Terraform is executed
#       args = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_id, "--region", var.region]
#     }
#   }
# }
# provider "kubernetes" {
#   host                   = module.eks.eks_cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.eks_cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     # This requires the awscli to be installed locally where Terraform is executed
#     args = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_id, "--region", var.region]
#   }
# }
# provider "kubectl" {
#   apply_retry_count      = 5
#   host                   = module.eks.eks_cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.eks_cluster_certificate_authority_data)
#   load_config_file       = false

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     # This requires the awscli to be installed locally where Terraform is executed
#     args = ["eks", "get-token", "--cluster-name", module.eks.eks_cluster_id]
#   }
# }

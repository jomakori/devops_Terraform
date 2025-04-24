###############################################################################################
#------------------------------------ Provider Versioning ------------------------------------# 
###############################################################################################
terraform {
  # Store state in GCP bucket
  backend "gcs" {
    bucket = "jm-terraform-state-bucket"
    prefix = "gke-cluster"
  }

  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.17.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.22.0"
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
data "google_client_config" "default" {}

# Helm
provider "helm" {
  kubernetes {
    host                   = module.gke.endpoint
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

# kubernetes/kubectl
provider "kubectl" {
  host                   = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}

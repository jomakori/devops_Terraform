###############################################################################################
#------------------------------------ Provider Versioning ------------------------------------# 
###############################################################################################
terraform {

  cloud {
    organization = "tf_jmakori"

    workspaces {
      name = "k8s-maklab-cluster"
    }
  }
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = ">= 0.5.1"
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

# Minikube
provider "minikube" {
  kubernetes_version = var.kubernetes_version
}


# Helm
provider "helm" {
  kubernetes = {
    config_path = var.k8s_config_path
  }
}

# kubectl
provider "kubectl" {
  config_path = var.k8s_config_path
}

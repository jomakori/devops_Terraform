###############################################################################################
#------------------------------------ Provider Versioning ------------------------------------# 
###############################################################################################
terraform {

  cloud {
    organization = "tf_jmakori"

    workspaces {
      name = "local_gitops-k8s-cluster"
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
  kubernetes_version = "v1.33.1"
}


# Helm
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# kubernetes/kubectl
provider "kubectl" {
  config_path = "~/.kube/config"
}

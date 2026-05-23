terraform {

  cloud {
    organization = "tf_jmakori"

    workspaces {
      name = "k8s-maklab-cluster"
    }
  }
  required_providers {
    doppler = {
      source  = "DopplerHQ/doppler"
      version = ">= 1.21.0"
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
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = ">= 0.6.0"
    }
  }
}

# Providers
provider "doppler" {
  doppler_token = var.DOPPLER_TOKEN
}
provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
provider "kubectl" {
  load_config_file = true
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}
provider "minikube" {
  kubernetes_version = var.cluster_config["kubernetes_version"]
}

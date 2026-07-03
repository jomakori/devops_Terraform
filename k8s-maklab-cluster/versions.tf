terraform {

  cloud {
    organization = "tf_jmakori"

    workspaces {
      name = "k8s-maklab-cluster"
    }
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.0.0"
    }
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
    k3d = {
      source  = "SneakyBugs/k3d"
      version = "1.0.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }
}

# Providers
provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}
provider "doppler" {
  doppler_token = var.DOPPLER_TOKEN
}
provider "k3d" {}
provider "helm" {
  kubernetes = {
    config_path = pathexpand("~/.kube/config")
  }
}
provider "kubectl" {
  load_config_file = true
}
provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

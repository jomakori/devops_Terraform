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
    host                   = k3d_cluster.maklab_cluster.host
    client_certificate     = base64decode(k3d_cluster.maklab_cluster.client_certificate)
    client_key             = base64decode(k3d_cluster.maklab_cluster.client_key)
    cluster_ca_certificate = base64decode(k3d_cluster.maklab_cluster.cluster_ca_certificate)
  }
}
provider "kubectl" {
  host                   = k3d_cluster.maklab_cluster.host
  client_certificate     = base64decode(k3d_cluster.maklab_cluster.client_certificate)
  client_key             = base64decode(k3d_cluster.maklab_cluster.client_key)
  cluster_ca_certificate = base64decode(k3d_cluster.maklab_cluster.cluster_ca_certificate)
  load_config_file       = false
}
provider "kubernetes" {
  host                   = k3d_cluster.maklab_cluster.host
  client_certificate     = base64decode(k3d_cluster.maklab_cluster.client_certificate)
  client_key             = base64decode(k3d_cluster.maklab_cluster.client_key)
  cluster_ca_certificate = base64decode(k3d_cluster.maklab_cluster.cluster_ca_certificate)
}

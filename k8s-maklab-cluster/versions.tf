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
      version = "~> 5.24"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = ">= 1.21.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
    k3d = {
      source  = "SneakyBugs/k3d"
      version = "1.0.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = ">= 0.16.0"
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
provider "github" {
  # Classic PAT with admin:repo_hook — the Actions automatic token cannot
  # manage repo webhooks (403 "not accessible by integration"). Set via
  # TF_VAR_GITHUB_TOKEN from Doppler.
  owner = "jomakori"
  token = var.GITHUB_TOKEN
}
provider "k3d" {}
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
provider "tailscale" {
  api_key = var.TAILSCALE_API_KEY
}

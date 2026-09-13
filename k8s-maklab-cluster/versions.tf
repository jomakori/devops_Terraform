terraform {

  cloud {
    organization = "tf_jmakori"

    workspaces {
      name = "k8s-maklab-cluster"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
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
# R2 is S3-compatible, so the pg-main bucket is managed through the AWS
# provider against R2's S3 endpoint rather than `cloudflare_r2_bucket`. The
# Cloudflare-native resource requires an API token carrying the R2 permission
# scope (a token used by everything else in this workspace); the S3 path
# authenticates with the R2 credentials the workspace already holds (var.R2_*).
# The three skips are required by R2 - they disable client-side S3 validation
# that R2 cannot satisfy. Ref:
# https://developers.cloudflare.com/r2/examples/terraform-aws/
provider "aws" {
  region     = "us-east-1"
  access_key = var.R2_ACCESS_KEY_ID
  secret_key = var.R2_SECRET_ACCESS_KEY

  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "https://${var.CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com"
  }
}

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

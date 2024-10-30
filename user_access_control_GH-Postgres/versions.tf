terraform {
  cloud {
    organization = "demo_org"

    workspaces {
      name = "user_access_control_prod"
    }
  }
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 5.0"
    }
    doppler = {
      source  = "DopplerHQ/doppler"
      version = ">= 1.9.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.22.0"
    }
  }
}

# Single Providers
provider "aws" {
  region = "us-east-2"
}
provider "github" {
  owner = "richcontext"
  token = var.GITHUB_TOKEN
}

# Dual providers for staging + production envs
## Doppler Providers
provider "doppler" {
  alias         = "staging"
  doppler_token = var.DOPPLER_STAGING_TOKEN
}
provider "doppler" {
  alias         = "production"
  doppler_token = var.DOPPLER_PROD_TOKEN
}

## Postgresql Providers
provider "postgresql" {
  alias = "staging"

  host     = var.STAGING_DB_HOST
  database = var.DB_NAME
  username = var.DB_USER
  password = var.DB_PASSWORD
  port     = 5432

  superuser = false
}

provider "postgresql" {
  alias = "production"

  host     = var.PROD_DB_HOST
  database = var.DB_NAME
  username = var.DB_USER
  password = var.DB_PASSWORD
  port     = 5432

  superuser = false
}

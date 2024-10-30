terraform {
  cloud {
    organization = "demo_org"

    workspaces {
      name = "vpc_access"
    }
  }
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Providers
provider "aws" {
  region = "us-east-2"
}

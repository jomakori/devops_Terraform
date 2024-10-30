terraform {
  cloud {
    organization = "demo_org"

    workspaces {
      name = "ec2_tower"
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.5"
}

# Custom Access to Tower
provider "aws" {
  region     = var.TOWER_REGION
  access_key = var.TOWER_ACCESS_KEY
  secret_key = var.TOWER_ACCESS_SECRET
}

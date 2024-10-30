terraform {
  cloud {
    organization = "demo_org"

    workspaces {
      name = "ecr"
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0"
}
module "resources" {
  source = "./resources"
}
provider "aws" {
  region = "us-east-2"
}

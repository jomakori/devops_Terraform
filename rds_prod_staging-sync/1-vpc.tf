locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  sg_rules = {
    rds = {
      rule        = "custom-tcp"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 5432
      to_port     = 5432
    }
    redis = {
      rule        = "custom-tcp"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 6379
      to_port     = 6379
    }
  }
}
################################################################################
# Supporting Resources
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.1"

  # Networking
  name               = "${var.name}-vpc"
  cidr               = var.vpc_cidr_block
  azs                = local.azs
  private_subnets    = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 4, k)]
  public_subnets     = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 8, k + 48)]
  enable_nat_gateway = true
  single_nat_gateway = true

  # Logging
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_class             = "STANDARD"
  flow_log_cloudwatch_log_group_retention_in_days = 180 # ACN req - 180 days

  tags = var.rds_tags
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Secure Ingress traffic - VPN/GH Actions only                             │
  └──────────────────────────────────────────────────────────────────────────┘
 */

## Create Shared Security Group for RDS access
module "shared_rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.1.0"

  name            = "${var.name}-sg"
  use_name_prefix = false
  description     = "Dedicated security group for RDS access - staging/prod"
  vpc_id          = module.vpc.vpc_id

  # Set Ingress Rules
  ingress_rules           = ["postgresql-tcp"]
  ingress_cidr_blocks     = [var.aws_eks_cidr_block] # Allows EKS traffic
  ingress_prefix_list_ids = ["pl-123456"]            # Allows VPN + CI traffic

  # Set Egress Rules
  ## disabled - DB doesn't need any external access

  tags = var.rds_tags

  depends_on = [
    module.vpc
  ]
}

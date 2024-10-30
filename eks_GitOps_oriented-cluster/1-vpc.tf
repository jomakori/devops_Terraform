locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = var.aws_vpc_cidr_block
}
################################################################################
# Supporting Resources
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.1"

  # Basic VPC info
  name = "${var.name}-vpc"
  cidr = local.vpc_cidr
  azs  = local.azs

  # Networking
  private_subnets    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets     = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  enable_nat_gateway = true
  single_nat_gateway = true
  ## For Private EKS:
  default_vpc_enable_dns_support   = true
  default_vpc_enable_dns_hostnames = true
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  # Enable flow logs
  ## Note: Encryption of logs are enabled by default via AWS managed key (auto-created by AWS)
  enable_flow_log                                 = true
  flow_log_destination_type                       = "cloud-watch-logs"
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_retention_in_days = 180 # Minimum 6 month retention

  # Tagging
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = "${var.name}-cluster" # used in karpenter nodeclass - for node placement
  }
  tags = var.tags
}

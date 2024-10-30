############################################################
############ CONNECT EKS VPC -> DB + Redis VPC #############
############################################################
module "vpc_peering" {
  source  = "cloudposse/vpc-peering/aws"
  version = ">= 1.0"

  name = "${var.name}-peering-connection"

  auto_accept                               = true
  requestor_allow_remote_vpc_dns_resolution = true
  acceptor_allow_remote_vpc_dns_resolution  = true

  # Source: EKS VPC
  requestor_vpc_id       = var.aws_eks_vpc_id
  requestor_ignore_cidrs = [var.aws_eks_cidr_block]
  # Destination: RDS VPC
  acceptor_vpc_id = module.vpc.vpc_id

  create_timeout = "5m"
  update_timeout = "5m"
  delete_timeout = "10m"

  tags = var.rds_tags

  depends_on = [module.vpc.vpc_id]
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Enable VPC peering connection routes to RDS VPC - from EKS VPC           │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "aws_route" "rds_routes" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id            = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block    = var.aws_eks_cidr_block
  vpc_peering_connection_id = module.vpc_peering.connection_id
}

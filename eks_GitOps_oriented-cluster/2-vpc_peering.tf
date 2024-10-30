############################################################
############ CONNECT EKS VPC -> DB + Redis VPC #############
############################################################
module "vpc_peering" {
  source  = "cloudposse/vpc-peering/aws"
  version = ">= 1.0"

  name        = "${var.name}-vpc-peering"
  environment = "prod"

  auto_accept                               = true
  requestor_allow_remote_vpc_dns_resolution = true
  acceptor_allow_remote_vpc_dns_resolution  = true
  requestor_vpc_id                          = module.vpc.vpc_id
  acceptor_vpc_id                           = "vpc-df7438b6"
  requestor_ignore_cidrs                    = [var.aws_vpc_cidr_block]
  create_timeout                            = "5m"
  update_timeout                            = "5m"
  delete_timeout                            = "10m"

  tags = merge(var.tags, {
    "usage" = "Connects ${var.name}-cluster to VPC hosting DBs + Redis",
  })

  depends_on = [module.vpc]
}

#################################################################
# ADD VPC PEERING CONNECTION TO VPC SUBNETS HOSTING REDIS & RDS #
#################################################################
locals {
  redis_rds_routetables = [
    "rtb-026d4b43df89e4350",
    "rtb-3385de5a",
    "rtb-3085de59"
  ]
}
resource "aws_route" "redis_rds_route" {
  count = length(local.redis_rds_routetables)

  route_table_id            = local.redis_rds_routetables[count.index]
  destination_cidr_block    = var.aws_vpc_cidr_block
  vpc_peering_connection_id = module.vpc_peering.connection_id
}

#############################################
# ADD SG Rules to connect to RDS DB + Redis #
#############################################
resource "aws_security_group_rule" "enable_rds_access" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.aws_vpc_cidr_block]
  security_group_id = var.rds_db_securitygroup

  description = "Enables ${var.name}-cluster access to RDS - via peering connection"
}

resource "aws_security_group_rule" "enable_elasticache_access" {
  type              = "ingress"
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
  cidr_blocks       = [var.aws_vpc_cidr_block]
  security_group_id = "sg-95c50bff" # different sg, compared to DB

  description = "Enables ${var.name}-cluster access to Elasticache - via peering connection"
}

#--------------------------------------------------------------------------------------------#
#------------------------------------ Create EKS Cluster ------------------------------------#
#--------------------------------------------------------------------------------------------#
# Grab Accenture VPN CIDR's
data "aws_ec2_managed_prefix_list" "accenture_vpn" {
  id = "pl-123456"
}
## Filter only the CIDR blocks
locals {
  vpn_cidrs = [for entry in data.aws_ec2_managed_prefix_list.accenture_vpn.entries : entry.cidr]
}

module "eks" {
  source  = "cloudposse/eks-cluster/aws"
  version = "4.1.0"

  #--------------------------------------------------------------------#
  #------------------------ Basic EKS Properties ----------------------#
  #--------------------------------------------------------------------#
  name               = var.name
  label_value_case   = "none"
  kubernetes_version = var.k8s_version

  enabled_cluster_log_types = ["audit", "authenticator"]

  #--------------------------------------------------------------------#
  #-------------------------- EKS Networking --------------------------#
  #--------------------------------------------------------------------#
  ## Note: SG rules for cluster are managed outside this module below
  subnet_ids = module.vpc.private_subnets

  ## Restrict EKS Cluster access: restricted external - private node traffic
  endpoint_public_access  = true
  endpoint_private_access = true
  public_access_cidrs     = local.vpn_cidrs

  #------------------------------------------------------------------------------------#
  #--------------------------------- EKS Access Controls ------------------------------#
  #------------------------------------------------------------------------------------#
  oidc_provider_enabled = true # Needed for IRSA roles associaton in EKS Blueprints
  access_entry_map = {
    # Terraform Service Account\
    (data.aws_caller_identity.current.arn) = {
      user_name         = "TerraformAdminUser"
      kubernetes_groups = ["devops"]
      access_policy_associations = {
        ClusterAdmin = {}
      }
    }
    # Azure SSO using Admin role
    "arn:aws:iam::376424775662:role/Admin" = {
      user_name         = "AzureAdminUser"
      kubernetes_groups = ["azure-users"]
      access_policy_associations = {
        ClusterAdmin = {}
      }
    }
    # Azure SSO using engineers role
    "arn:aws:iam::376424775662:role/engineers" = {
      user_name         = "AzureEngineerUser"
      kubernetes_groups = ["azure-users"]
      access_policy_associations = {
        ClusterAdmin = {}
      }
    }
    # AWS-native SSO - Admin
    "arn:aws:iam::376424775662:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_LZ_AdminAccess_e3f58631d4d4d13c" = {
      user_name         = "AWS_SSO_admin"
      kubernetes_groups = ["azure-users"]
      access_policy_associations = {
        ClusterAdmin = {}
      }
    }
  }
  # Role for Karpenter Nodes
  ## IMPORTANT: Comment out until `module.eks_blueprints_addons` has been created
  access_entries_for_nodes = {
    EC2_LINUX = [module.eks_blueprints_addons.karpenter.node_iam_role_arn]
  }

  tags       = var.tags
  depends_on = [module.vpc_peering]
}

#--------------------------------------------------------------------------------------------------#
#---------------------------------- EKS Security Group - Ingress Rules ----------------------------#
#--------------------------------------------------------------------------------------------------#
locals {
  security_group_rules = [
    {
      description = "Open port to Prometheus - for Lens Metrics"
      from_port   = 10250
      to_port     = 10250
      protocol    = "TCP"
    },
    {
      description = "Open port to Metrics Server"
      from_port   = 9090
      to_port     = 9090
      protocol    = "TCP"
    }
  ]
}
resource "aws_security_group_rule" "cluster_sg_rules" {
  for_each          = { for idx, rule in local.security_group_rules : idx => rule }
  type              = "ingress"
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = module.eks.eks_cluster_managed_security_group_id
  self              = true

  depends_on = [module.eks.eks_cluster_managed_security_group_id]
}

#-------------------------------------------------------------------------------------------------#
#---------------------------------- EKS Security Group - Egress Rules ----------------------------#
#-------------------------------------------------------------------------------------------------#
# Egress rule for HTTP
resource "aws_security_group_rule" "http_egress" {
  security_group_id = module.eks.eks_cluster_managed_security_group_id
  description       = "Egress rule for HTTP"

  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# Egress rule for HTTPS
resource "aws_security_group_rule" "https_egress" {
  security_group_id = module.eks.eks_cluster_managed_security_group_id
  description       = "Egress rule for HTTPS"

  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# Egress rule for DNS
resource "aws_security_group_rule" "dns_egress" {
  security_group_id = module.eks.eks_cluster_managed_security_group_id
  description       = "Egress rule for DNS"

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]
}

# Egress rule for SSH
resource "aws_security_group_rule" "ssh_egress" {
  security_group_id = module.eks.eks_cluster_managed_security_group_id
  description       = "Egress rule for SSH"

  type        = "egress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# Egress rule for service ports - port range: 1024-65535
## CAUTION: Make sure service ports are within this range or add a rule for it
resource "aws_security_group_rule" "service_egress" {
  security_group_id = module.eks.eks_cluster_managed_security_group_id
  description       = "Egress rule for service ports - ports 1024-65535"

  type        = "egress"
  from_port   = 1024
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

#------------------------------------------------------------------------------------------------#
#---------------------------------- EKS LB Controller - Egress Rules ----------------------------#
#------------------------------------------------------------------------------------------------#
data "aws_security_groups" "k8s_managed" {
  filter {
    name   = "description"
    values = ["[k8s] Managed SecurityGroup for LoadBalancer"]
  }
}

# Egress rules for http
resource "aws_security_group_rule" "lb_http_rules" {
  for_each    = toset(data.aws_security_groups.k8s_managed.ids)
  description = "Set HTTP egress rules for LB"

  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = each.value
}

# Egress rules for https
resource "aws_security_group_rule" "lb_https_rules" {
  for_each    = toset(data.aws_security_groups.k8s_managed.ids)
  description = "Set HTTPS egress rules for LB"

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = each.value
}

#--------------------------------------------------------------------------------------------#
#---------------------------------- Create EKS Node Group -----------------------------------#
#--------------------------------------------------------------------------------------------#
module "eks_node_group" {
  source  = "cloudposse/eks-node-group/aws"
  version = "2.12.0"

  #-------------------------------------#
  #-------- Basic EKS Properties -------#
  #-------------------------------------#
  name               = var.name
  cluster_name       = module.eks.eks_cluster_id
  subnet_ids         = module.vpc.private_subnets
  kubernetes_version = [var.k8s_version]

  #---------------------------------------------#
  #--- Access Permissions for NodeGroup role ---#
  #---------------------------------------------#
  node_role_policy_arns = [
    ## Grants permissions to ssh via AWS SSM
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    ## Grants permissions for ebs-csi controller
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]

  #--------------------------------------#
  #-- Node Group compute configuration --#
  #--------------------------------------#
  ami_type       = "AL2_x86_64" # Amazon Linux 2 / 64 bit
  instance_types = ["t3a.medium"]
  min_size       = 1
  max_size       = 3
  desired_size   = 3

  #--------------------------------------#
  #---- Node Group EBS configuration ----#
  #--------------------------------------#
  block_device_mappings = [{
    device_name           = "/dev/xvda"
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }]

  #--------------------------------------#
  #-- Node Group maintainance settings --#
  #--------------------------------------#
  create_before_destroy                = true
  force_update_version                 = true # ignores PodEviction rules
  replace_node_group_on_version_update = true
  update_config = [{
    max_unavailable_percentage = 20
  }]


  tags = merge(tomap({
    isto_containers = "AWS_EKS" }), # Accenture ISD Requirement
    var.tags
  )
}

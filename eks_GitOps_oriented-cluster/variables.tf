#--------------------------------------------------------------------------------------------#
#-------------------------------------- EKS Variables ---------------------------------------#
#--------------------------------------------------------------------------------------------#
variable "name" {
  type        = string
  description = "Name of Deployment"
  default     = "jm-k8s"
}
variable "k8s_version" {
  type        = string
  description = "Kubernetes Version for EKS."
  # increment to upgrade kubernetes cluster, based on versioning here: 
  # - https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions-standard.html
  default = "1.31"
}
variable "environment" {
  type        = string
  description = "Type of Deployment"
  default     = "Production"
}
variable "tags" {
  type = map(string)
  default = {
    environment = "Production"
    deployment  = "jm-k8s-cluster"
  }
}

#--------------------------------------------------------------------------------------------#
#-------------------------------------- VPC Variables ---------------------------------------#
#--------------------------------------------------------------------------------------------#
variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-2"
}
variable "azs" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}
variable "aws_vpc_cidr_block" {
  default     = "172.81.0.0/16"
  description = "The VPC cidr block for EKS"
}

variable "aws_vpc_enable_dns_hostnames" {
  default = true
}

variable "aws_vpc_enable_dns_support" {
  default = true
}

variable "aws_vpc_instance_tenancy" {
  default = "default"
}

variable "aws_vpc_tc_category" {
  default = "vpc"
}

variable "rds_db_securitygroup" {
  default = "sg-550efa3d"
}

# #--------------------------------------------------------------------------------------------#
# #------------------------------- GitOps Configuration Values --------------------------------#
# #--------------------------------------------------------------------------------------------#
# variable "gitops_repo" {
#   type        = string
#   description = "Repo hosting microservices and applications for the EKS cluster"
#   default     = "https://github.com/richcontext/kubernetes.git"
# }

# variable "gitops_branch" {
#   description = "Git branch for apps + services"
#   type        = string
#   default     = "HEAD"
# }
# variable "gitops_services_path" {
#   description = "Git repository path for addons"
#   type        = string
#   default     = "services/argocd-appset"
# }
# variable "gitops_apps_path" {
#   description = "Git repository path for workload"
#   type        = string
#   default     = "apps/argocd-appset"
# }

# #--------------------------------------------------------------------------------------------#
# #------------------------------- GitOps secrets from Doppler --------------------------------#
# #--------------------------------------------------------------------------------------------#
# variable "GITHUB_TOKEN" { # from Doppler
#   type      = string
#   sensitive = true
# }
# variable "DD_API_KEY" { # from Doppler
#   type      = string
#   sensitive = true
# }
# variable "DD_APP_KEY" { # from Doppler
#   type      = string
#   sensitive = true
# }
# variable "ARGOCD_GH_SSO_APPID" { # from Doppler
#   type      = string
#   sensitive = true
# }

# variable "SLACK_ENOTIFY_TOKEN" {
#   description = "The Slack token for the #e-notify-deployments channel - via doppler"
# }

# variable "ARGOCD_GH_SSO_SECRET" { # from Doppler
#   type      = string
#   sensitive = true
# }

# variable "PROD_DB_HOST" {
#   description = "Production DB endpoint"
#   sensitive   = true
# }

# variable "STAGING_DB_HOST" {
#   description = "Staging DB endpoint"
#   sensitive   = true
# }

# variable "DOPPLER_PROD_TOKEN" { # from Doppler
#   type      = string
#   sensitive = true
# }

# variable "DOPPLER_STAGING_TOKEN" { # from Doppler
#   type      = string
#   sensitive = true
# }

# variable "DOPPLER_RETAILER_PROD" { # from Doppler
#   type      = string
#   sensitive = true
# }

# variable "REDIS_PW" {
#   description = "Login Credential for RDS"
#   sensitive   = true
# }

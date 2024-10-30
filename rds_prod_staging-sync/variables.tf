#--------------------------------------------------------------------------------------------#
#-------------------------------------- Main Variables ---------------------------------------#
#--------------------------------------------------------------------------------------------#
variable "name" {
  type        = string
  description = "Name of Deployment"
  default     = "demo_app-rds"
}

variable "rds_tags" {
  type = map(string)
  default = {
    usage = "Deployment of the Commerce Engine RDS cluster - Staging + Prod"
  }
}

variable "DOPPLER_STAGING_TOKEN" {
  type = string
}

variable "DOPPLER_PROD_TOKEN" {
  type = string
}
#--------------------------------------------------------------------------------------------#
#-------------------------------------- VPC Variables ---------------------------------------#
#--------------------------------------------------------------------------------------------#
variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-2"
}

variable "vpc_cidr_block" {
  description = "The CIDR block used for this deployment"
  default     = "172.11.0.0/16"
}

variable "DB_USER" {
  type = string
}
variable "DB_PASSWORD" {
  type = string
}

variable "ACN_MODULES_TOKEN" {
  type = string
}

#--------------------------------------------------------------------------------------------#
#-------------------------------------- RDS Variables ---------------------------------------#
#--------------------------------------------------------------------------------------------#
variable "engine" {
  description = "The RDS Engine Type"
  default     = "aurora-postgresql"
}

variable "postgres_version" {
  type        = string
  description = "Postgres Version of the RDS Cluster"

  default = "15.4"
}

variable "postgres_version_class" {
  type        = string
  description = "Dependent of postgres version: "

  default = "aurora-postgresql15"
}

variable "scaling_mode" {
  description = "Server based or serverless"
  default     = "provisioned"
}

variable "logging_type" {
  description = "The type of RDS logs to record in CloudWatch"
  default     = ["stderr"]
}

# EKS variables
variable "aws_eks_cidr_block" {
  default     = "172.81.0.0/16"
  description = "The VPC cidr block for EKS"
}
variable "aws_eks_vpc_id" {
  description = "The VPC ID for EKS"
  default     = "vpc-0d21a956acd69aa75"
}
variable "rds_enforce_ssl" {
  description = "Enforce SSL for RDS"
  default = [
    {
      name         = "rds.force_ssl"
      value        = "0"
      apply_method = "pending-reboot"
    }
  ]
}

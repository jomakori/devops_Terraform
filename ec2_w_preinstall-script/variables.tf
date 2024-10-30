/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Variables - Global                                                       │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "TOWER_REGION" {
  description = "AWS Region - Tower"
}
variable "TOWER_ACCESS_KEY" {
  description = "AWS Access Key - Tower"
}
variable "TOWER_ACCESS_SECRET" {
  description = "AWS Access Secret - Tower"
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Variables - EC2 Gateway                                                  │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "gateway_name" {
  description = "Naming Strategy for Gateway resources"
  default     = "katana-reporting"
}
variable "gateway_az" {
  default     = "us-west-2b"
  description = "Availability zone for the EC2 Gateway"
}

variable "gateway_tags" {
  default = {
    usage      = "EC2 Gateway - for Katana Reporting"
    managed_by = "terraform"
  }
}

variable "gateway_environments" {
  default = [
    "prod",
    "staging"
  ]
  description = "EC2 Gateway environments"
}

variable "POWERBI_CLIENT_ID" {
  description = "PowerBI Credentials for script"
}
variable "POWERBI_CLIENT_SECRET" {
  description = "PowerBI Credentials for script"
}
variable "POWERBI_TENANT_ID" {
  description = "PowerBI Credentials for script"
}
variable "POWERBI_RECOVER_KEY" {
  description = "PowerBI Credentials for script"
}

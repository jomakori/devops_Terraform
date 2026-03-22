#  Common vars
variable "cidr_blocks" {
  description = "CIDR blocks for networking"
  type = object({
    vcn_cidr     = string
    public_cidr  = string
    private_cidr = string
    global_cidr  = string
  })
  default = {
    vcn_cidr     = "10.0.0.0/16"
    public_cidr  = "10.0.1.0/24"
    private_cidr = "10.0.2.0/24"
    global_cidr  = "0.0.0.0/0"
  }
}

variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
  default     = "production"
}

variable "name" {
  description = "Name for resources (e.g., maklab-base0)"
  type        = string
  default     = "maklab-base0"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "oci-arm-vm"
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
  default = {
    project     = "oci-arm-vm"
    environment = "development"
    managed_by  = "terraform"
  }
}

variable "tailscale_key_expiry_days" {
  description = "Tailscale auth key expiry in days"
  type        = number
  default     = 90
}

variable "tcp_protocol" {
  description = "TCP protocol number"
  type        = string
  default     = "6"
}

variable "vm_shape" {
  description = "OCI VM shape for ARM instances"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

# Secret vars
variable "DOPPLER_TOKEN" {
  description = "Doppler token for accessing secrets"
  type        = string
  sensitive   = true
}

variable "OCI_FINGERPRINT" {
  description = "OCI API key fingerprint"
  type        = string
  sensitive   = true
  default     = ""
}

variable "OCI_PRIVATE_KEY" {
  description = "OCI private key for API authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "OCI_TENANCY_OCID" {
  description = "OCI Tenancy OCID"
  type        = string
  sensitive   = true
}

variable "OCI_USER_OCID" {
  description = "OCI User OCID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "TAILSCALE_API_KEY" {
  description = "Tailscale API key for generating auth keys"
  type        = string
  sensitive   = true
}

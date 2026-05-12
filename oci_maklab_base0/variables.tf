#  config vars
variable "project_config" {
  description = "Common project configuration values for resource naming and identity"
  type        = map(string)
  default = {
    environment  = "production"
    name         = "maklab-base0"
    project_name = "oci-arm-vm"
    region       = "us-ashburn-1"
    tcp_protocol = "6"
  }
}

variable "vm_config" {
  description = "VM compute configuration (shape, cpu, memory)"
  type        = map(any)
  default = {
    shape              = "VM.Standard.A1.Flex"
    cpu                = 2
    memory             = 24
    log_retention_days = 30
  }
}

#  other vars
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

variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
  default = {
    project     = "oci-arm-vm"
    environment = "development"
    managed_by  = "terraform"
  }
}

# secret vars
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
  description = "Tailscale API key for managing tailscale provider"
  type        = string
  sensitive   = true
}

variable "TAILSCALE_AUTH_KEY" {
  description = "Tailscale Auth Key for creating new keys for VMs"
  type        = string
  sensitive   = true
}

variable "TAILSCALE_ID" {
  description = "Tailscale Workspace ID"
  type        = string
  sensitive   = true
}

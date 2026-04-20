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

variable "log_retention_days" {
  description = "OCI Logging retention period in days"
  type        = number
  default     = 30
}

variable "tcp_protocol" {
  description = "TCP protocol number"
  type        = string
  default     = "6"
}

variable "vm_shape" {
  description = "OCI VM shape (ARM or x86). Common options: VM.Standard.A1.Flex (ARM), VM.Standard.A2.Flex (ARM), VM.Standard.E4.Flex (x86)"
  type        = string
  default     = "VM.Standard.A2.Flex"
}

variable "vm_cpu" {
  description = "Number of OCPUs for flexible shapes. Reduce if experiencing capacity issues."
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory in GB for flexible shapes"
  type        = number
  default     = 12
}

variable "alternative_regions" {
  description = "List of alternative regions to try if primary region has capacity issues"
  type        = list(string)
  default     = ["us-phoenix-1", "eu-frankfurt-1", "uk-london-1"]
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

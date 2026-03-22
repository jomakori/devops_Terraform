# OCI Provider Configuration
provider "oci" {
  fingerprint      = var.OCI_FINGERPRINT
  private_key      = var.OCI_PRIVATE_KEY
  region           = var.region
  tenancy_ocid     = var.OCI_TENANCY_OCID
  user_ocid        = var.OCI_USER_OCID
}

# Tailscale Provider Configuration
provider "tailscale" {
  api_key = var.TAILSCALE_API_KEY
}

# Doppler Provider Configuration
provider "doppler" {
  doppler_token = var.DOPPLER_TOKEN
}

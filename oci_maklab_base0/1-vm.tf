# Networking - vcn, subnets, internet gateway
module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "~> 3.0"

  compartment_id = var.OCI_TENANCY_OCID
  region         = var.region

  # vcn configuration
  vcn_name      = "${var.name}-vcn"
  vcn_dns_label = "maklab"
  vcn_cidrs     = [var.cidr_blocks.vcn_cidr]

  # internet gateway
  create_internet_gateway       = true
  internet_gateway_display_name = "${var.name}-igw"

  # subnets
  create_nat_gateway     = false
  create_service_gateway = false

  subnets = {
    public = {
      display_name = "${var.name}-public-subnet"
      cidr_block   = var.cidr_blocks.public_cidr
      dns_label    = "public"
      type         = "public"
    }
  }

  freeform_tags = var.tags
}

# Security - security lists (firewall rules)
resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.OCI_TENANCY_OCID
  vcn_id         = module.vcn.vcn_id
  display_name   = "${var.name}-public-security-list"
  freeform_tags  = var.tags

  # ingress rules
  ingress_security_rules {
    protocol    = var.tcp_protocol
    source      = var.cidr_blocks.global_cidr
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = var.tcp_protocol
    source      = var.cidr_blocks.global_cidr
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = var.tcp_protocol
    source      = var.cidr_blocks.global_cidr
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # egress rules - allow all outbound
  egress_security_rules {
    protocol         = "all"
    destination      = var.cidr_blocks.global_cidr
    destination_type = "CIDR_BLOCK"
  }
}

# Tailscale - auth key generation & rotation (defaults to 90-day expiry)
resource "tailscale_tailnet_key" "vm_auth_key" {
  expiry        = var.tailscale_key_expiry_days
  preauthorized = true
  reusable      = true
}

# Cloud-init - simple Tailscale installation
locals {
  cloud_init = templatefile("${path.module}/scripts/cloud-init.tftpl", {
    auth_key = tailscale_tailnet_key.vm_auth_key.key
    hostname = "${var.name}-vm"
  })
}

# Shape availability validation
locals {
  shape_available = length(data.oci_core_shapes.shape_validation.shapes) > 0
}

# Compute - arm vm instance
module "vm" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "~> 2.4"

  compartment_ocid      = var.OCI_TENANCY_OCID
  instance_display_name = "${var.name}-vm"
  source_ocid           = data.oci_core_images.oracle_linux_arm.images[0].id
  subnet_ocids          = [module.vcn.subnet_id["public"]]

  shape                       = var.vm_shape
  instance_flex_ocpus         = var.vm_cpu
  instance_flex_memory_in_gbs = var.vm_memory

  ssh_public_keys            = ""
  user_data                  = base64encode(local.cloud_init)
  public_ip                  = "EPHEMERAL"
  block_storage_sizes_in_gbs = [200]

  freeform_tags = var.tags

  depends_on = [oci_core_security_list.public_security_list, tailscale_tailnet_key.vm_auth_key]
}

# Doppler - secret storage
resource "doppler_secret" "tailscale_auth_key" {
  project = "devops"
  config  = "ci"

  name  = "TF_VAR_TAILSCALE_AUTH_KEY"
  value = tailscale_tailnet_key.vm_auth_key.key

  depends_on = [tailscale_tailnet_key.vm_auth_key]
}

# OCI Logging - Log group for Tailscale installation
module "logging" {
  source  = "oracle-terraform-modules/logging/oci"
  version = "~> 0.4"

  compartment_id = var.OCI_TENANCY_OCID
  tenancy_id     = var.OCI_TENANCY_OCID
  service_logdef = {}

  linux_logdef = {
    tailscale_install = {
      loggroup = "${var.name}-tailscale-logs"
      dg       = "tailscale_install_logs"
      path     = ["/var/log/tailscale_install.log", "/var/log/tailscale"]
    }
  }

  log_retention_duration = var.log_retention_days
  loggroup_tags          = var.tags

  depends_on = [module.vm]
}

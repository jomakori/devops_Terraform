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

# Tailscale - cloud-init configuration using official Tailscale Terraform module
module "tailscale_install" {
  source  = "tailscale/tailscale/cloudinit"
  version = "~> 0.0.11"

  auth_key = tailscale_tailnet_key.vm_auth_key.key
  hostname = "${var.name}-vm"

  accept_routes = true
}

# Compute - arm vm instance
module "compute_instance" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "~> 2.4"

  compartment_ocid      = var.OCI_TENANCY_OCID
  instance_display_name = "${var.name}-vm"
  source_ocid           = data.oci_core_images.oracle_linux_arm.images[0].id
  subnet_ocids          = [module.vcn.subnet_id["public"]]

  shape                       = var.vm_shape
  instance_flex_ocpus         = 4
  instance_flex_memory_in_gbs = 24

  ssh_public_keys            = ""
  user_data                  = module.tailscale_install.rendered
  public_ip                  = "EPHEMERAL"
  block_storage_sizes_in_gbs = [200]

  freeform_tags = var.tags

  depends_on = [oci_core_security_list.public_security_list, tailscale_tailnet_key.vm_auth_key]
}

# Doppler - secret storage
resource "doppler_secret" "tailscale_auth_key" {
  project = var.name
  config  = var.environment

  name  = "TF_VAR_TAILSCALE_AUTH_KEY"
  value = tailscale_tailnet_key.vm_auth_key.key

  depends_on = [tailscale_tailnet_key.vm_auth_key]
}

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

  accept_routes = true
  auth_key      = tailscale_tailnet_key.vm_auth_key.key
  enable_ssh    = true
  hostname      = "${var.name}-vm"
  max_retries   = 10
  retry_delay   = 10

  additional_parts = [
    {
      filename     = "network_ready.sh"
      content_type = "text/x-shellscript"
      content      = <<-EOT
        #!/bin/sh
        # Wait for network connectivity before proceeding
        max_attempts=30
        attempt=1
        while [ $attempt -le $max_attempts ]; do
          if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            echo "Network connectivity confirmed"
            exit 0
          fi
          echo "Waiting for network connectivity... ($attempt/$max_attempts)"
          sleep 2
          attempt=$((attempt + 1))
        done
        echo "Failed to establish network connectivity after $max_attempts attempts"
        exit 1
      EOT
    },
    {
      filename     = "udp_offloads.sh"
      content_type = "text/x-shellscript"
      content      = <<-EOT
        #!/bin/sh
        # Override script to avoid network device detection failures
        echo "Skipping UDP offloads optimization for OCI instance"
        exit 0
      EOT
    }
  ]
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

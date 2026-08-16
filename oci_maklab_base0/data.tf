# Data sources for OCI resources

# Validate VM shape is available in the region
data "oci_core_shapes" "shape_validation" {
  compartment_id = var.OCI_TENANCY_OCID

  filter {
    name   = "shape"
    values = [var.vm_config["shape"]]
  }
}

# Oracle Linux 10.1 ARM image lookup
data "oci_core_images" "oracle_linux_arm" {
  compartment_id = var.OCI_TENANCY_OCID

  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = var.vm_config["shape"] # filter to ARM only
}

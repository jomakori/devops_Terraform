# Data sources for OCI resources

# Oracle Linux 10.1 ARM image lookup
data "oci_core_images" "oracle_linux_arm" {
  compartment_id = var.OCI_TENANCY_OCID

  operating_system         = "Oracle Linux"
  operating_system_version = "10"
  shape                    = var.vm_shape # filter to ARM only
}

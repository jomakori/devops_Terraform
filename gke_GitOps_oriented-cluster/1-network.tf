module "network" {
  source  = "terraform-google-modules/network/google"
  version = ">= 7.5"

  # Definition
  project_id   = var.project_id
  network_name = "${var.name}-network"

  # Define network subnets
  subnets = [
    for subnet_name, cidr in var.subnet_cidr_ranges : {
      subnet_name   = subnet_name
      subnet_ip     = cidr
      subnet_region = var.region
    }
  ]

  # Set cidr ranges for pods and services in k8s
  secondary_ranges = {
    "subnet-a" = [
      for k8s_attr, cidr in var.k8s_cidr_ranges : {
        range_name    = k8s_attr
        ip_cidr_range = cidr
      }
    ]
  }
}

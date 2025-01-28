module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = ">= 35.0.1"

  # Required variables
  project_id = var.project_id
  name       = var.name
  region     = var.region
  network    = module.network.network_name
  subnetwork = module.network.subnets_names[0]
  ## From k8s_cidr_ranges var
  ip_range_pods     = "pods"
  ip_range_services = "services"

  # # Private cluster configuration
  # enable_private_nodes    = true
  # enable_private_endpoint = false
  # master_ipv4_cidr_block  = var.k8s_cidr_ranges["control-plane"]

  # Restrict public endpoint access
  master_authorized_networks = [
    {
      cidr_block   = "71.195.18.35/32"
      display_name = "vpn-access"
    }
  ]

  # Node pool configuration
  node_pools = [
    {
      name               = "${var.name}-workers"
      machine_type       = "e2-micro"
      initial_node_count = 1
      min_count          = 1
      max_count          = 3
      disk_size_gb       = 30
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
    }
  ]

  # Addons
  horizontal_pod_autoscaling = true
  http_load_balancing        = true
  network_policy             = true
}

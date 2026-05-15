resource "minikube_cluster" "maklab_cluster" {
  # Cluster Configuration
  cluster_name      = "${var.name}-cluster"
  cni               = var.cluster_config["cni"]
  container_runtime = var.cluster_config["container_runtime"]
  driver            = var.cluster_config["driver"]
  vm                = true

  # Access Configuration
  apiserver_names = [var.TAILSCALE_TUNNEL]

  # Node Configuration
  cpus      = var.vm_config["cpus"]
  memory    = var.vm_config["memory"]
  disk_size = var.vm_config["disk_size"]
  nodes     = tonumber(var.vm_config["worker_nodes"])

  addons = [
    "metrics-server",
    "nvidia-device-plugin",
    "storage-provisioner-rancher"
  ]
}

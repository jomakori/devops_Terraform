resource "minikube_cluster" "maklab_cluster" {
  # Cluster Configuration
  cluster_name      = "${var.name}-cluster"
  cni               = var.cluster_config["cni"]
  container_runtime = var.cluster_config["container_runtime"]
  driver            = var.cluster_config["driver"]
  vm                = true

  # Access Configuration
  # TAILSCALE_HOST is the full FQDN for remote access
  apiserver_names = ["${var.name}.${var.TAILSCALE_HOST}"]

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

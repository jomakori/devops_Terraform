resource "minikube_cluster" "maklab_cluster" {
  # Cluster Configuration
  cluster_name = var.name
  cni          = "flannel" # robust pod networking for multi-node clusters
  driver       = "docker"

  # Access Configuration
  apiserver_names = [var.TAILSCALE_TUNNEL]

  # Node Configuration
  cpus   = 2
  memory = 2048
  nodes  = var.worker_nodes

  addons = [
    "csi-hostpath-driver",
    "ingress",
    "metrics-server"
  ]
}

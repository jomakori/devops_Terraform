resource "minikube_cluster" "maklab_cluster" {
  # Cluster Configuration
  apiserver_names = [var.TAILSCALE_TUNNEL]
  cluster_name    = var.name
  cni             = "flannel" # robust pod networking for multi-node clusters
  driver          = "docker"
  # Node Configuration
  cpus   = 4
  memory = 2048
  nodes  = var.worker_nodes


  addons = [
    "csi-hostpath-driver",
    "ingress",
    "metrics-server",
    "storage-provisioner-rancher",
    "volumesnapshots"
  ]
}

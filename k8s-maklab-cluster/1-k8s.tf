resource "minikube_cluster" "local_k8s" {
  vm              = true
  driver          = "docker"
  cluster_name    = var.name
  nodes           = 6
  cni             = "flannel" # Flannel provides robust pod networking for multi-node clusters
  apiserver_names = [var.TAILSCALE_TUNNEL]
  addons = [
    "ingress",
    "metrics-server",
    "storage-provisioner",
    "volumesnapshots"
  ]
}

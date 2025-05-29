resource "minikube_cluster" "local_k8s" {
  vm           = true
  driver       = "docker"
  cluster_name = var.name
  nodes        = 3
  cni          = "flannel" # Flannel provides robust pod networking for multi-node clusters
  addons = [
    "default-storageclass",
    "ingress",
    "metrics-server",
    "storage-provisioner",
    "volumesnapshots"
  ]
}

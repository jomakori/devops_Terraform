resource "minikube_cluster" "local_k8s" {
  vm              = true
  driver          = "docker"
  cluster_name    = var.name
  nodes           = 4
  cni             = "flannel" # Flannel provides robust pod networking for multi-node clusters
  apiserver_names = [ var.TAILSCALE_TUNNEL ]
  addons = [
    "csi-hostpath-driver",
    "ingress",
    "storage-provisioner",
    "volumesnapshots"
  ]
}

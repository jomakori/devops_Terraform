resource "minikube_cluster" "local_k8s" {
  vm              = true
  driver          = "none"
  cluster_name    = var.name
  nodes           = 3
  cni             = "flannel" # Flannel provides robust pod networking for multi-node clusters
  apiserver_ips   = ["127.0.0.1"]
  apiserver_names = ["jmak-lab.tail2354a3.ts.net"]
  addons = [
    "ingress",
    "metrics-server",
    "storage-provisioner",
    "volumesnapshots"
  ]
}

locals {
  cluster_name = k3d_cluster.maklab_cluster.name
}

output "kubeconfig" {
  description = "Kubeconfig for accessing the k3d cluster"
  sensitive   = true
  value       = k3d_cluster.maklab_cluster.kubeconfig
}

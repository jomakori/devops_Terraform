locals {
  cluster_name = k3d_cluster.maklab_cluster.name
  tunnel_host  = "jmak-lab.tail2354a3.ts.net"
}

output "kubeconfig" {
  description = "Kubeconfig for accessing the k3d cluster via Tailscale tunnel"
  sensitive   = true
  value       = replace(k3d_cluster.maklab_cluster.kubeconfig, "/https://0\\.0\\.0\\.0:\\d+/", "https://${local.tunnel_host}:443")
}

output "public_tunnel" {
  description = "Tailscale tunnel endpoint for remote cluster access"
  value       = "https://${local.tunnel_host}:443"
}

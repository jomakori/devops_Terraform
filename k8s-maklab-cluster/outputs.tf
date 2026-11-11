locals {
  cluster_name = var.cluster_config["name"]
  tunnel_host  = "jmak-lab.tail2354a3.ts.net"
}

# kubeconfig output removed 2026-08-20 with k3d_cluster (see 1-k8s.tf / removed.tf).
# CI obtains cluster access at runtime via `tailscale configure kubeconfig`.

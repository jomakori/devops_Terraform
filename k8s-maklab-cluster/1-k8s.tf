/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Prerequisite: Install iscsi + nfs-common in colima VM for Longhorn       │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "null_resource" "colima_longhorn_deps" {
  triggers = {
    # Re-run if cluster name changes (indicates new colima setup)
    cluster_name = var.cluster_config["name"]
  }

  provisioner "local-exec" {
    command = <<-EOT
      colima ssh -- sudo apt-get update -qq &&
      colima ssh -- sudo apt-get install -y -qq open-iscsi nfs-common
      echo "Longhorn dependencies installed in colima VM"
    EOT
  }
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ k3d Cluster — 1 server + 3 agents on colima (arm64)                      │
  │                                                                            │
  │ Image: rancher/k3s (bundled iptables-nft shim for nftables compat)       │
  │ Nodes: server=1 (control plane), agents=3 (workload)                      │
  │ Labels: intent=apps on all agent nodes (nodeSelector for app workloads)   │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "k3d_cluster" "maklab_cluster" {
  name = var.cluster_config["name"]

  k3d_config = <<-EOT
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: ${var.cluster_config["name"]}
servers: 1
agents: 3
image: rancher/k3s:${var.cluster_config["kubernetes_version"]}
options:
  k3s:
    extraArgs:
      # Use bundled iptables-nft shim — stable on arm64, avoids host nftables conflicts
      - arg: --prefer-bundled-bin
        nodeFilters:
          - server:*
          - agent:*
      # Label all agent nodes so app workloads target them via nodeSelector
      - arg: --node-label=intent=apps
        nodeFilters:
          - agent:*
  kubeconfig:
    updateDefaultKubeconfig: true
    switchCurrentContext: true
EOT

  depends_on = [null_resource.colima_longhorn_deps]
}



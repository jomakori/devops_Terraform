/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Prerequisite: Install iscsi + nfs-common in colima VM for Longhorn       │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "null_resource" "colima_longhorn_deps" {
  triggers = {
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
  │ Provider: 3rein/k3d v0.0.4 — native schema, configurable kube_api host   │
  │ API:     https://192.168.65.2:6443 (stable, no SSH tunnel dependency)    │
  │ Image:   rancher/k3s (bundled iptables-nft shim for nftables compat)     │
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
ports:
  - port: 6443:6443
    nodeFilters:
      - loadbalancer
options:
  k3s:
    extraArgs:
      - arg: --prefer-bundled-bin
        nodeFilters:
          - server:*
          - agent:*
      - arg: --tls-san=192.168.65.2
        nodeFilters:
          - server:*
      - arg: --node-label=intent=apps
        nodeFilters:
          - agent:*
  kubeconfig:
    updateDefaultKubeconfig: true
    switchCurrentContext: true
EOT

  depends_on = [null_resource.colima_longhorn_deps]
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ CoreDNS — forward external DNS to 8.8.8.8                                │
  │ k3d default forwards to node resolv.conf which uses colima NAT DNS       │
  │ that doesn't reliably forward UDP from pod network                       │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "kubectl_manifest" "coredns_config" {
  yaml_body = <<-YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
        }
        hosts /etc/coredns/NodeHosts {
          ttl 60
          reload 15s
          fallthrough
        }
        prometheus :9153
        cache 30
        loop
        reload
        loadbalance
        import /etc/coredns/custom/*.override
        forward . 8.8.8.8 8.8.4.4
    }
YAML

  depends_on = [k3d_cluster.maklab_cluster]
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Kubeconfig — auto-written to ~/.kube/config after every apply            │
  │ Replaces 0.0.0.0:<port> with 192.168.65.2:6443 for stable access       │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "local_file" "kubeconfig" {
  content         = replace(k3d_cluster.maklab_cluster.kubeconfig, "/https://0\\.0\\.0\\.0:\\d+/", "https://192.168.65.2:6443")
  filename        = pathexpand("~/.kube/config")
  file_permission = "0600"

  depends_on = [k3d_cluster.maklab_cluster]
}

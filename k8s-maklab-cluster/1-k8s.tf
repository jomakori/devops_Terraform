/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ k3d Cluster — 1 server + 3 agents on OrbStack (arm64)                    │
  │ Provider: SneakyBugs/k3d v1.0.1                                          │
  │ Image: custom k3s with iscsi pre-installed (built via make k3s-image)    │
  │        Dockerfile at docker/Dockerfile — copies open-iscsi from Alpine   │
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
agents: ${var.cluster_config["worker_nodes"]}
image: ${var.k3s_image}
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
      - arg: --node-label=intent=apps
        nodeFilters:
          - agent:*
      - arg: --tls-san=${local.tunnel_host}
        nodeFilters:
          - server:*
  kubeconfig:
    updateDefaultKubeconfig: true
    switchCurrentContext: true
EOT
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ CoreDNS upstream — use k3d node's own DNS (Docker bridge)                │
  │ Google DNS (8.8.8.8) unreliable from k3d pod network via UDP             │
  └──────────────────────────────────────────────────────────────────────────┘
 */
data "external" "k3d_dns" {
  program = ["sh", "-c", "echo \"{\\\"ip\\\":\\\"$(docker exec k3d-${var.cluster_config["name"]}-server-0 cat /etc/resolv.conf | grep nameserver | head -1 | awk '{print $2}')\\\"}\""]

  depends_on = [k3d_cluster.maklab_cluster]
}

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
        forward . ${data.external.k3d_dns.result.ip}
    }
YAML

  depends_on = [k3d_cluster.maklab_cluster, data.external.k3d_dns]
}

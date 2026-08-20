/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ k3d Cluster — 1 server + 3 agents on OrbStack (arm64)                    │
  │ Provider: SneakyBugs/k3d v1.0.1                                          │
  │ Image: custom k3s with iscsi pre-installed (built via make k3s-image)    │
  │        Dockerfile at k8s-maklab-cluster/Dockerfile — open-iscsi from Alpine │
  └──────────────────────────────────────────────────────────────────────────┘
 */
# k3d_cluster.maklab_cluster — DISABLED 2026-08-20. The SneakyBugs/k3d provider
# requires the `k3d` CLI on PATH and shells out to it on refresh; CI runners
# lack it and cannot see the Mac's OrbStack docker anyway (cluster is created
# out-of-band on the Mac). State entry handled by removed.tf. If you need TF to
# manage the cluster, run terraform locally on the Mac (k3d present there).
resource "null_resource" "k3d_cluster_managed_out_of_band" {
  triggers = {
    note = "k3d cluster jmak-lab is bootstrapped on the Mac (make k3s-image + k3d create); not managed from CI"
  }
}

# CoreDNS settings

## cache cluster.local, resource bounds, node-spread, HPA, and PDB for reliable DNS
resource "kubectl_manifest" "coredns_config" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        log
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf { max_concurrent 1000 }
        cache 30
        loop
        reload
        loadbalance
    }
YAML

}

## Auto-scale CoreDNS based on load
resource "kubectl_manifest" "coredns_hpa" {
  yaml_body = <<YAML
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: coredns
  namespace: kube-system
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: coredns
  minReplicas: 2
  maxReplicas: 6
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
YAML

  depends_on = [kubectl_manifest.coredns_config]
}

## requests/limits, and pod anti-affinity for node-failure resilience
resource "kubectl_manifest" "coredns_deployment" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  k8s-app: kube-dns
              topologyKey: kubernetes.io/hostname
      containers:
      - name: coredns
        resources:
          requests:
            cpu: 100m
            memory: 70Mi
          limits:
            cpu: 200m
            memory: 150Mi
YAML

  depends_on = [kubectl_manifest.coredns_config]
}

# Ensure at least 1 CoreDNS pod stays available during node maintenance
resource "kubectl_manifest" "coredns_pdb" {
  yaml_body = <<YAML
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: coredns-pdb
  namespace: kube-system
spec:
  minAvailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
YAML

  depends_on = [kubectl_manifest.coredns_deployment]
}

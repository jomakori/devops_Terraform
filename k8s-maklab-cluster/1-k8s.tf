# The k3s/k3d cluster is provisioned out-of-band (not Terraform-managed).
# The old minikube_cluster resource was removed — keeping it here would create
# a second cluster on the next apply. removed.tf records its state cleanup.
# resource "minikube_cluster" "maklab_cluster" {
#   cluster_name      = "${var.cluster_config["name"]}-cluster"
#   cni               = var.cluster_config["cni"]
#   container_runtime = var.cluster_config["container_runtime"]
#   driver            = var.cluster_config["driver"]
#   vm                = true
#   apiserver_names   = ["${var.cluster_config["name"]}.${var.TAILSCALE_HOST}"]
#   cpus              = var.cluster_config["cpus"]
#   memory            = var.cluster_config["memory"]
#   disk_size         = var.cluster_config["disk_size"]
#   nodes             = tonumber(var.cluster_config["worker_nodes"])
#   extra_config      = ["kubelet.node-labels=intent=apps"]
#   addons = ["storage-provisioner-rancher"]
# }

# Stale: minikube host paths. local-path provisioner runs natively on k3d.
# resource "kubectl_manifest" "local_path_config" {
#   yaml_body = <<YAML
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: local-path-config
#   namespace: local-path-storage
# data:
#   config.json: |-
#     {
#       "nodePathMap": [
#         { "node": "DEFAULT_PATH_FOR_NON_LISTED_NODES", "paths": ["/minikube-host/Shared/local-path-provisioner"] }
#       ]
#     }
#   helperPod.yaml: |-
#     apiVersion: v1
#     kind: Pod
#     metadata:
#       name: helper-pod
#     spec:
#       containers:
#         - name: helper-pod
#           image: docker.io/busybox:stable@sha256:3fbc632167424a6d997e74f52b878d7cc478225cffac6bc977eedfe51c7f4e79
#           imagePullPolicy: IfNotPresent
#   setup: |-
#     #!/bin/sh
#     set -eu
#     mkdir -m 0777 -p "$VOL_DIR"
#   teardown: |-
#     #!/bin/sh
#     set -eu
#     rm -rf "$VOL_DIR"
# YAML
# }

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

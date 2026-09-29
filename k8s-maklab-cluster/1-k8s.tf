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

# OrbStack VM memory — the host the k3d cluster runs on. The 4 k3d node
# containers advertise the VM's full RAM as allocatable (each ~16GB), so the
# scheduler sees 64GB of claims over a 16GB VM and over-commits it ~2:1 — the
# root cause of the recurring CoreDNS OOM cascade (Committed_AS 27.9GB vs
# CommitLimit 25.7GB, MemFree ~137MB at 01:53Z flares).
#
# Enforced via orb config set, which lives on the Mac — the local-exec guard
# makes this a no-op on CI runners (no `orb` binary there), and takes effect
# only when applied from the Mac (the cluster's home). Takes effect on the next
# OrbStack restart; raising it does NOT restart OrbStack by itself.
#
# Also provisions a disk-backed swapfile inside the VM so the cluster can
# commit past RAM before OOM (zram alone is RAM-backed compression, not
# capacity). Idempotent: skips if the swapfile already exists. OrbStack boots
# do NOT auto-swapon fstab entries, so a oneshot systemd service
# (swapfile-swapon.service) guarantees re-activation on every restart.
resource "terraform_data" "orbstack_vm_memory" {
  # triggers_replace (NOT input): terraform_data provisioners only run on
  # resource creation. `input` treats value changes as an in-place update and
  # silently skips the local-exec — the swapfile/memory would drift. Any value
  # change here = replacement = provisioner re-runs. (An ephemeral object can
  # hold both, but keeping the trigger block single-purpose avoids surprises.)
  triggers_replace = {
    memory_mib   = var.orbstack_memory_mib
    swapfile_mib = var.orbstack_swapfile_mib
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      if ! command -v orb >/dev/null 2>&1; then
        echo "orb CLI not found on PATH — Skipping OrbStack VM memory/swap enforcement (expected on CI runners)"
        exit 0
      fi
      current="$(orb config get memory_mib 2>/dev/null || echo unknown)"
      echo "OrbStack VM memory: ${var.orbstack_memory_mib} MiB (was: $current) — effective after OrbStack restart"
      orb config set memory_mib "${var.orbstack_memory_mib}"

      echo "Ensuring ${var.orbstack_swapfile_mib} MiB swapfile in VM..."
      orb run sh -c '
        set -e
        SUDO=""
        if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
        if $SUDO [ -f /swapfile ]; then
          actual=$($SUDO stat -c %s /swapfile 2>/dev/null || echo 0)
          if [ "$actual" -ge $(( ${var.orbstack_swapfile_mib} * 1024 * 1024 )) ]; then
            echo "/swapfile exists at ${var.orbstack_swapfile_mib} MiB or larger — OK"
          else
            echo "/swapfile too small ($actual bytes) — recreating"
            $SUDO swapoff /swapfile 2>/dev/null || true
            $SUDO rm -f /swapfile
            $SUDO fallocate -l ${var.orbstack_swapfile_mib}M /swapfile || $SUDO dd if=/dev/zero of=/swapfile bs=1M count=${var.orbstack_swapfile_mib} status=none
            $SUDO chmod 600 /swapfile
            $SUDO mkswap /swapfile >/dev/null
          fi
        else
          $SUDO fallocate -l ${var.orbstack_swapfile_mib}M /swapfile || $SUDO dd if=/dev/zero of=/swapfile bs=1M count=${var.orbstack_swapfile_mib} status=none
          $SUDO chmod 600 /swapfile
          $SUDO mkswap /swapfile >/dev/null
          echo "/swapfile created (${var.orbstack_swapfile_mib} MiB)"
        fi

        if ! $SUDO swapon --show | grep -q "^/swapfile"; then
          $SUDO swapon /swapfile
          echo "/swapfile activated"
        else
          echo "/swapfile already active"
        fi
        $SUDO grep -q "^/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" | $SUDO tee -a /etc/fstab >/dev/null

        # OrbStack boots do NOT auto-swapon fstab entries (swap unit type
        # unsupported in its systemd). Install a oneshot service so the
        # swapfile survives every restart. Idempotent.
        $SUDO tee /etc/systemd/system/swapfile-swapon.service >/dev/null <<'\''UNIT'\''
[Unit]
Description=Enable OrbStack VM disk-backed swapfile (/swapfile)
After=local-fs.target
ConditionPathExists=/swapfile

[Service]
Type=oneshot
ExecStart=/bin/sh -c "swapon /swapfile 2>/dev/null || true"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable swapfile-swapon.service >/dev/null 2>&1
        if ! $SUDO systemctl is-active --quiet swapfile-swapon.service; then
          $SUDO systemctl start swapfile-swapon.service
        fi
        echo "swapfile boot-service ensured: swapfile-swapon.service ($($SUDO systemctl is-active swapfile-swapon.service))"
      '
    EOT
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

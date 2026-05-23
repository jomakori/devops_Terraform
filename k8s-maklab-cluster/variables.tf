/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Cluster variables                                                        │
  └──────────────────────────────────────────────────────────────────────────┘
 */


variable "cluster_config" {
  description = "Cluster-wide configuration for the minikube cluster"
  type        = map(string)
  default = {
    cni                = "flannel"
    container_runtime  = "containerd"
    cpus               = "max"
    disk_size          = "10000mb"
    driver             = "krunkit"
    kubernetes_version = "v1.35.1"
    memory             = "15g"
    name               = "jmak-lab"
    worker_nodes       = "4"
  }
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Doppler-passed variables                                                 │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "TAILSCALE_HOST" {
  description = "URL to Tailscale Tunnel"
}

variable "DOPPLER_TOKEN" {
  description = "Used by TF provider to create service account + machine token for ESO."
  type        = string
  sensitive   = true
}


/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ GitOps Variables                                                         │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "gitops_config" {
  description = "GitOps configuration passed to ArgoCD App-of-Apps Helm values"
  type        = map(string)
  default = {
    apps_path      = "apps/argocd-appset"
    argoNamespace  = "argocd"
    argoProject    = "default"
    clusterDomain  = "maklab.net"
    clusterServer  = "https://kubernetes.default.svc"
    repo           = "https://github.com/jomakori/gke_GitOps.git"
    services_path  = "services/argocd-appset"
    storageClass   = "local-path"
    targetRevision = "HEAD"
  }
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Cluster variables                                                        │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "name" {
  description = "Namespace for workspace resources"
  default     = "jmak-lab"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for k8s cluster. For latest version, run `minikube config defaults kubernetes-version`"
  default     = "v1.35.1"
}

variable "k8s_cidr_ranges" {
  description = "Mapping of CIDR ranges for K8s pods + services"
  type        = map(any)
  default = {
    "pods"     = "10.0.0.0/16"
    "services" = "127.0.0.0/16"
  }
}

variable "k8s_config_path" {
  description = "Kubernetes config file path"
  type        = string
  default     = "~/.kube/config"
}

variable "cluster_config" {
  description = "Cluster-wide configuration for the minikube cluster"
  type        = map(string)
  default = {
    cni               = "flannel"
    container_runtime = "containerd"
    driver            = "krunkit"
  }
}

variable "vm_config" {
  description = "VM resource settings for minikube cluster nodes"
  type        = map(string)
  default = {
    cpus         = "max"
    memory       = "15g"
    disk_size    = "10000mb"
    worker_nodes = "4"
  }
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ GitOps Variables                                                         │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "gitops_repo" {
  description = "Where GitOps Helm charts are stored"
  default     = "https://github.com/jomakori/gke_GitOps.git"
}

variable "gitops_branch" {
  description = "Branch to follow for GitOps deployment"
  default     = "HEAD"
}

variable "gitops_apps_path" {
  description = "Path to ArgoCD App manifests for Apps"
  default     = "apps/argocd-appset"
}

variable "gitops_services_path" {
  description = "Path to ArgoCD App manifests for Services"
  default     = "services/argocd-appset"
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Cluster Infrastructure Variables                                         │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "TAILSCALE_HOST" {
  description = "URL to Tailscale Tunnel"
}

variable "doppler_token" {
  description = "Doppler personal token with admin access. Used by TF provider to create service account + machine token for ESO."
  type        = string
  sensitive   = true
}

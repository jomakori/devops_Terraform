/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Workspace variables                                                      │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "name" {
  description = "Namespace for workspace resources"
  default     = "gitops-k8s-cluster"
}
variable "subnet_cidr_ranges" {
  description = "Mapping of CIDR ranges for VPC networking"
  type        = map(string)
  default = {
    "subnet-a" = "10.0.0.0/16"
    "subnet-b" = "10.1.0.0/16"
  }
}

variable "k8s_cidr_ranges" {
  description = "Mapping of CIDR ranges for K8s pods + services"
  type        = map(any)
  default = {
    "pods"          = "192.168.0.0/16"
    "services"      = "192.169.0.0/16"
    "control-plane" = "172.16.0.0/28"
  }
}

variable "WHITELIST_K8S_ACCESS" {
  description = "Doppler var - List of IP addresses to whitelist for access to the cluster"
  type        = map(string)
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ GitOps variables                                                         │
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

# App Access tokens to Doppler
## Note: Use `TF_VAR_` prefix in Doppler to pass in these variables
variable "DOPPLER_PROD_TOKEN" {
  description = "Doppler var - App Access token to Doppler for PROD "
}
variable "DOPPLER_STAGING_TOKEN" {
  description = "Doppler var - App Access token to Doppler for staging "
}

# Service variables
## Note: Use `TF_VAR_` prefix in Doppler to pass in these variables
variable "PG_USER" {
  description = "Doppler var - Postgres user for app access"
}
variable "PG_PW" {
  description = "Doppler var - Postgres password for app access"
  sensitive   = true

}
variable "GRAFANA_ADMIN" {
  description = "Doppler var - Grafana admin username"
}
variable "GRAFANA_PW" {
  description = "Doppler var - Grafana admin password"
  sensitive   = true
}
variable "TAILSCALE_CLIENTID" {
  description = "Client ID for Tailscale"
  sensitive   = true
}
variable "TAILSCALE_CLIENTSEC" {
  description = "Client Secret for Tailscale"
  sensitive   = true
}

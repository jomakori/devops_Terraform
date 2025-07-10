/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Workspace variables                                                      │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "name" {
  description = "Namespace for workspace resources"
  default     = "maklab-cluster"
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

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ GitOps variables - Local                                                 │
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
  │ GitOps Variables - Doppler                                               │
  |                                                                          |
  | > Note: Use `TF_VAR_` prefix in Doppler to pass in these variables       |
  └──────────────────────────────────────────────────────────────────────────┘
 */

## Template Vars
variable "TAILSCALE_TUNNEL" {
  description = "URL to Tailscale Tunnel"
}

## App Vars
variable "DOPPLER_PROD_TOKEN" {
  description = "Doppler var - App Access token to Doppler for PROD "
}
variable "DOPPLER_STAGING_TOKEN" {
  description = "Doppler var - App Access token to Doppler for staging "
}

## Service Vars
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
variable "TAPIR_SSO_CLIENT_ID" {
  description = "Client ID for Tailscale"
  sensitive   = true
}
variable "TAPIR_SSO_CLIENT_SECRET" {
  description = "Client Secret for Tailscale"
  sensitive   = true
}
variable "MONGODB_HOST" {
  description = "MongoDB host for service access"
}
variable "MONGODB_USER" {
  description = "MongoDB user for service access"
}
variable "MONGODB_PW" {
  description = "MongoDB password for service access"
  sensitive   = true
}

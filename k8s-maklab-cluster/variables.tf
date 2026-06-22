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
    disk_size          = "20000mb"
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

variable "CLOUDFLARE_API_TOKEN" {
  description = "Cloudflare API token with DNS and Zero Trust permissions."
  type        = string
  sensitive   = true
}

variable "CLOUDFLARE_ACCOUNT_ID" {
  description = "Cloudflare account ID for Zero Trust tunnel creation."
  type        = string
}

variable "tunnel_config" {
  description = "Cloudflare tunnel configuration"
  type        = map(string)
  default = {
    tunnel_name     = "maklab-cluster"
    doppler_project = "devops"
    doppler_config  = "svc_cloudflare"
  }
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Cloudflare Zero Trust Access Variables                                  │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "CF_TEAM" {
  description = "Cloudflare Zero Trust team name (subdomain in cloudflareaccess.com). Set via TF_VAR_CF_TEAM."
  type        = string
  default     = "jmaklab"
}

variable "GOOGLE_OAUTH_CLIENT_ID" {
  description = "Google OAuth 2.0 client ID for CF Access IdP. Set via TF_VAR_GOOGLE_OAUTH_CLIENT_ID from Doppler."
  type        = string
}

variable "GOOGLE_OAUTH_CLIENT_SECRET" {
  description = "Google OAuth 2.0 client secret for CF Access IdP. Set via TF_VAR_GOOGLE_OAUTH_CLIENT_SECRET from Doppler."
  type        = string
  sensitive   = true
}

variable "ACCESS_TEAM_DOMAIN" {
  description = "Cloudflare Zero Trust team domain. Set via TF_VAR_ACCESS_TEAM_DOMAIN from Doppler."
  type        = string
}

variable "ACCESS_AUDIENCE_TAG" {
  description = "CF Access application AUD tag. Set via TF_VAR_ACCESS_AUDIENCE_TAG from Doppler."
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
    apps_path          = "apps/argocd-appset"
    argoNamespace      = "argocd"
    argoProject        = "default"
    clusterDomain      = "maklab.net"
    clusterServer      = "https://kubernetes.default.svc"
    repo               = "https://github.com/jomakori/gke_GitOps.git"
    services_path      = "services/argocd-appset"
    storageClass       = "local-path"
    targetRevision     = "HEAD"
  }
}

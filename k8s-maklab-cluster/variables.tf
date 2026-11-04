/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Cluster variables                                                        │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "cluster_config" {
  description = "Cluster name consumed by the GitOps Helm values and outputs. The rest of the cluster shape (k3s image, node counts, k3s flags) lives in k3d-cluster.yaml, which is the source of truth."
  type        = map(string)
  default = {
    name = "maklab-cluster"
  }
}

variable "orbstack_memory_mib" {
  description = "OrbStack VM memory in MiB (53248 = 52GiB). The k3d cluster runs inside this VM; the 4 node containers advertise its full RAM as allocatable, so a 16GiB VM gets over-committed ~2:1 (recurring CoreDNS OOMs). 52GiB is the max that leaves ~12GiB on the 64GiB Mac for macOS + kernel (measured host overhead ~5GiB). Enforced by terraform_data.orbstack_vm_memory — effective after an OrbStack restart."
  type        = number
  default     = 53248
}

variable "orbstack_swapfile_mib" {
  description = "Disk-backed swapfile size in MiB created inside the OrbStack VM (32768 = 32GiB on the /dev/vdb1 data disk, which has 70GiB free). Complements the VM's zram (RAM-backed compression) + 1GiB built-in swap; together they lift CommitLimit to ~75GiB so the cluster can commit far past RAM before OOM. Provisioned idempotently by terraform_data.orbstack_vm_memory — effective immediately on apply (no restart needed)."
  type        = number
  default     = 32768
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Doppler-passed variables                                                 │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "DOPPLER_TOKEN" {
  description = "Used by TF provider to create service account + machine token for ESO."
  type        = string
  sensitive   = true
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
  │ Cloudflare Zero Trust (account IdP + Istio JWT validation)              │
  └──────────────────────────────────────────────────────────────────────────┘
*/


variable "ACCESS_TEAM_DOMAIN" {
  description = "Cloudflare Zero Trust team domain. Set via TF_VAR_ACCESS_TEAM_DOMAIN from Doppler."
  type        = string
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

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Tailscale Variables                                                      │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "TAILSCALE_API_KEY" {
  description = "Tailscale API key (api_key:write scope) — creates/manages the operator OAuth client. Set via TF_VAR_TAILSCALE_API_KEY from Doppler."
  type        = string
  sensitive   = true
}

/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ R2 Backup Variables (StackGres pg-main)                                  │
  └──────────────────────────────────────────────────────────────────────────┘
 */


variable "GITHUB_TOKEN" {
  description = "Classic PAT with admin:repo_hook — the Actions automatic token cannot manage repo webhooks (403 'not accessible by integration'). Set via TF_VAR_GITHUB_TOKEN from Doppler."
  type        = string
  sensitive   = true
}

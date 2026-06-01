# k8s-maklab-cluster

Terraform-managed local Minikube Kubernetes cluster for the **jmak-lab** environment, deployed via the krunkit driver on macOS and orchestrated entirely through ArgoCD GitOps.

## Architecture & Flow

Dependency chain (strict `depends_on`, left to right):

```
1-k8s.tf               ← provisions the Minikube cluster (v1.35.1, 4 workers, flannel CNI, containerd)
                            CoreDNS hardened: resource bounds, HPA (2-6 replicas), anti-affinity, PDB
                            Tailscale FQDN for remote API access

2-eso.tf               ← creates external-secrets namespace + stores Doppler personal token as K8s Secret
                            ClusterSecretStores in the GitOps repo reference this token with their own project+config

3-managed_services.tf  ← installs ArgoCD (helm_release.argocd) — ArgoCD can't manage itself

4-gitops.tf            ← creates "services" ArgoCD Application via App-of-Apps pattern
                            Points at gke_GitOps repo → ArgoCD auto-syncs (prune + self-heal)
                            "apps" Application is commented out — ready to activate when app workloads are ready

5-cloudflare-tunnel.tf ← Cloudflare Zero Trust tunnel + wildcard DNS + tunnel token stored to Doppler
                            Requires services (ArgoCD syncs Istio + cert-manager) already running
```

Dependency: `5 ← depends_on ← 4 ← depends_on ← 3 ← depends_on ← 2 ← depends_on ← 1`

### Structure

```
.
├── 1-k8s.tf                  # Cluster provisioning
├── 2-eso.tf                  # ESO bootstrap — namespace + token secret
├── 3-managed_services.tf     # ArgoCD installation
├── 4-gitops.tf               # App-of-Apps manifests (services active, apps commented out)
├── 5-cloudflare-tunnel.tf    # Cloudflare tunnel + DNS + Doppler token injection
├── data.tf                   # Cloudflare zone data source
├── variables.tf              # cluster_config, gitops_config, tunnel_config, CLOUDFLARE_*, DOPPLER_TOKEN, TAILSCALE_HOST
├── outputs.tf                # Kubeconfig with Tailscale endpoint
├── versions.tf               # Provider versions + Terraform Cloud config
├── helm/
│   └── argocd-values.yaml    # ArgoCD Helm overrides
└── argocd_app-of-apps/
    ├── services.yml          # Application template for 3rd-party services
    └── apps.yml              # Application template for app workloads (ready but unused)
```

## Secrets

No app/service secrets pass through Terraform variables or `terraform.tfvars`. Everything flows through ESO + Doppler:

1. Terraform stores `var.DOPPLER_TOKEN` (personal token) as a K8s Secret in `external-secrets`.
2. ClusterSecretStore resources in the GitOps repo reference that token with their `project` + `config`.
3. ExternalSecrets use `dataFrom.extract` with zero rewrite rules — K8s Secret keys match Doppler key names. `refreshInterval: 1m`.
4. Pods consume via standard `secretKeyRef`.

### Infrastructure Secrets (set via `TF_VAR_` env vars — no defaults)

| Variable | Source | Used By |
|----------|--------|---------|
| `TAILSCALE_HOST` | Tailscale FQDN | Cluster API server remote access |
| `DOPPLER_TOKEN` | Doppler personal token | ESO bootstrap K8s Secret |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token | Tunnel creation + DNS records |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID | Zero Trust tunnel resource |

## Usage

```bash
# Prerequisites: Terraform >= 1.6, Minikube + krunkit, Tailscale, Doppler CLI
terraform login
export TF_VAR_TAILSCALE_HOST="your-tailscale-fqdn"
export TF_VAR_DOPPLER_TOKEN="dp.ct.your-personal-token"
export TF_VAR_CLOUDFLARE_API_TOKEN="your-cf-api-token"
export TF_VAR_CLOUDFLARE_ACCOUNT_ID="your-cf-account-id"

terraform plan
terraform apply

# Access cluster
terraform output -raw kubeconfig > ~/.kube/jmak-lab-config
export KUBECONFIG=~/.kube/jmak-lab-config
kubectl get nodes

# Access ArgoCD
kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | >= 4.0.0 |
| <a name="requirement_doppler"></a> [doppler](#requirement\_doppler) | >= 1.21.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.19.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.22.0 |
| <a name="requirement_minikube"></a> [minikube](#requirement\_minikube) | >= 0.6.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 5.19.1 |
| <a name="provider_doppler"></a> [doppler](#provider\_doppler) | 1.21.2 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.2 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_minikube"></a> [minikube](#provider\_minikube) | 0.6.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_dns_record.wildcard_maklab](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared.maklab](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared_config.maklab](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zero_trust_tunnel_cloudflared_config) | resource |
| [doppler_secret.tunnel_id](https://registry.terraform.io/providers/DopplerHQ/doppler/latest/docs/resources/secret) | resource |
| [doppler_secret.tunnel_token](https://registry.terraform.io/providers/DopplerHQ/doppler/latest/docs/resources/secret) | resource |
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.coredns_config](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.coredns_deployment](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.coredns_hpa](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.coredns_pdb](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.doppler_machine_token_secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.eso_namespace](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.services](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [minikube_cluster.maklab_cluster](https://registry.terraform.io/providers/scott-the-programmer/minikube/latest/docs/resources/cluster) | resource |
| [random_id.tunnel_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [cloudflare_zero_trust_tunnel_cloudflared_token.maklab](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zero_trust_tunnel_cloudflared_token) | data source |
| [cloudflare_zone.maklab](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_CLOUDFLARE_ACCOUNT_ID"></a> [CLOUDFLARE\_ACCOUNT\_ID](#input\_CLOUDFLARE\_ACCOUNT\_ID) | Cloudflare account ID for Zero Trust tunnel creation. | `string` | n/a | yes |
| <a name="input_CLOUDFLARE_API_TOKEN"></a> [CLOUDFLARE\_API\_TOKEN](#input\_CLOUDFLARE\_API\_TOKEN) | Cloudflare API token with DNS and Zero Trust permissions. | `string` | n/a | yes |
| <a name="input_DOPPLER_TOKEN"></a> [DOPPLER\_TOKEN](#input\_DOPPLER\_TOKEN) | Used by TF provider to create service account + machine token for ESO. | `string` | n/a | yes |
| <a name="input_TAILSCALE_HOST"></a> [TAILSCALE\_HOST](#input\_TAILSCALE\_HOST) | URL to Tailscale Tunnel | `any` | n/a | yes |
| <a name="input_cluster_config"></a> [cluster\_config](#input\_cluster\_config) | Cluster-wide configuration for the minikube cluster | `map(string)` | <pre>{<br/>  "cni": "flannel",<br/>  "container_runtime": "containerd",<br/>  "cpus": "max",<br/>  "disk_size": "10000mb",<br/>  "driver": "krunkit",<br/>  "kubernetes_version": "v1.35.1",<br/>  "memory": "15g",<br/>  "name": "jmak-lab",<br/>  "worker_nodes": "4"<br/>}</pre> | no |
| <a name="input_gitops_config"></a> [gitops\_config](#input\_gitops\_config) | GitOps configuration passed to ArgoCD App-of-Apps Helm values | `map(string)` | <pre>{<br/>  "apps_path": "apps/argocd-appset",<br/>  "argoNamespace": "argocd",<br/>  "argoProject": "default",<br/>  "clusterDomain": "maklab.net",<br/>  "clusterServer": "https://kubernetes.default.svc",<br/>  "repo": "https://github.com/jomakori/gke_GitOps.git",<br/>  "services_path": "services/argocd-appset",<br/>  "storageClass": "local-path",<br/>  "targetRevision": "HEAD"<br/>}</pre> | no |
| <a name="input_tunnel_config"></a> [tunnel\_config](#input\_tunnel\_config) | Cloudflare tunnel configuration | `map(string)` | <pre>{<br/>  "doppler_config": "svc_cloudflare",<br/>  "doppler_project": "devops",<br/>  "tunnel_name": "maklab-cluster"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig for accessing the minikube cluster via Tailscale tunnel |
<!-- END_TF_DOCS -->
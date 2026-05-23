# k8s-maklab-cluster

Terraform-managed local Minikube Kubernetes cluster for the **jmak-lab** environment, deployed via the krunkit driver on macOS and orchestrated entirely through ArgoCD GitOps.

## Architecture

The infrastructure is split into three Terraform files, each building on the previous:

### 1. Cluster — [`1-k8s.tf`](1-k8s.tf)

| Setting | Value |
|---------|-------|
| Kubernetes version | `v1.35.1` |
| Nodes | 4 workers |
| Driver | krunkit (macOS VM) |
| CNI | flannel |
| Container runtime | containerd |
| API server | Tailscale FQDN for remote access |
| Addons | storage-provisioner-rancher |

**CoreDNS hardening** — The cluster applies production-grade DNS reliability:

- **Resource bounds** — requests (100m CPU / 70Mi memory) and limits (200m CPU / 150Mi memory) prevent starvation and noisy-neighbor problems.
- **HPA** — autoscales CoreDNS from 2–6 replicas at 70% CPU or 80% memory utilization.
- **Pod anti-affinity** — prefers spreading CoreDNS pods across distinct nodes (`kubernetes.io/hostname`).
- **PodDisruptionBudget** — guarantees at least 1 CoreDNS replica stays available during node maintenance.

### 2. Managed Services — [`2-managed_services.tf`](2-managed_services.tf)

A single Helm release bootstraps **ArgoCD** (since ArgoCD cannot manage itself). Configuration:

| Setting | Value |
|---------|-------|
| Chart | argo-cd from `argo-helm` |
| Namespace | `argocd` |
| Ingress | Disabled (accessed via `kubectl port-forward`) |
| Service type | NodePort |
| Autoscaling | Enabled (controller + repoServer, min 1 replica, 70% CPU/memory targets) |
| Web terminal | Enabled (`exec.enabled: true`) |
| Server insecure | `true` (for local port-forward) |

Values file: [`helm/argocd-values.yaml`](helm/argocd-values.yaml)

### 3. GitOps — [`3-gitops.tf`](3-gitops.tf)

Uses the **App-of-Apps** pattern to let ArgoCD manage everything beyond itself. Two Application manifests split the cluster into distinct ownership:

- **Services** — 3rd-party services (Grafana, Postgres operator, MongoDB, etc.) consumed as managed dependencies. Synced from `services/argocd-appset/` in the [gke_GitOps](https://github.com/jomakori/gke_GitOps) repo.
- **Apps** — my own application workloads deployed on top of those services. Synced from `apps/argocd-appset/`.

### 4. ESO + Doppler Bootstrap — [`4-eso.tf`](4-eso.tf)

Creates Doppler service tokens for each project+config pair and stores them as K8s Secrets in the `external-secrets` namespace. These are consumed by `ClusterSecretStore` resources in the GitOps repo, enabling External Secrets Operator (ESO) to fetch secrets directly from Doppler — bypassing Terraform entirely for app and service secrets.

## GitOps Flow

```
Terraform (this repo)
  │
  ├── minikube_cluster.maklab_cluster     ← provisions the K8s cluster
  ├── helm_release.argocd                 ← installs ArgoCD
  ├── kubectl_manifest.services           ← creates the "services" ArgoCD Application
  └── kubectl_manifest.apps              ← creates the "apps" ArgoCD Application
        │                                       │
        │                                       ▼
        │                               gke_GitOps repo
        │                                 ├── services/argocd-appset/      ← 3rd-party infra
        │                                 │     └── Grafana + Loki + Promtail
        │                                 │         CloudNative-PG (Postgres operator)
        │                                 │         MongoDB
        │                                 │         … other shared services
        │                                 │
        │                                 └── apps/argocd-appset/         ← my own workloads
        │                                       └── Helm charts
```

Changes to the GitOps repo are automatically synced by ArgoCD (prune + self-heal enabled with exponential backoff retry).

## Secrets Management

Secrets are managed via **ESO (External Secrets Operator) + Doppler**, with a single exception for cluster infrastructure.

| Variable | Source | Used By |
|----------|--------|---------|
| `TAILSCALE_HOST` | Tailscale (set as `TF_VAR_`) | Cluster API server FQDN |

- **`TAILSCALE_HOST`** is the only remaining `TF_VAR_` secret. It is cluster infrastructure (not an app/service secret), so it stays as a Terraform variable used by `1-k8s.tf` and `outputs.tf`.
- **All app and service secrets** (Grafana, Postgres, MongoDB, Doppler tokens, etc.) have been removed from Terraform variables. They now flow through ESO + Doppler directly.
- Terraform (via `4-eso.tf`) stores a single Doppler machine token as a K8s Secret in the `external-secrets/` namespace → `ClusterSecretStore` resources in the GitOps repo (one per config) all reference this same token, each specifying their own `project` + `config` → ESO fetches the real secret values from Doppler → pods consume them via standard `ExternalSecret` resources.

This means `terraform apply` no longer needs to know about any application credentials — those are managed entirely within the Doppler dashboard and synced by ESO.

## Remote Access

The cluster API server is exposed via a Tailscale tunnel. The `kubeconfig` output embeds:
- Server: `https://{name}.{TAILSCALE_HOST}:443`
- CA certificate, client certificate, and client key (all base64-encoded)

To use:
```bash
terraform output -raw kubeconfig > ~/.kube/jmak-lab-config
export KUBECONFIG=~/.kube/jmak-lab-config
kubectl get nodes
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) with [krunkit driver](https://minikube.sigs.k8s.io/docs/drivers/krunkit/)
- [Tailscale](https://tailscale.com/) for remote node access
- A [Terraform Cloud](https://app.terraform.io/) account (workspace: `k8s-maklab-cluster` in org `tf_jmakori`)
- [Doppler CLI](https://docs.doppler.com/docs/cli) (for ESO service token management)

## Usage

```bash
# Authenticate with Terraform Cloud
terraform login

# Set the cluster infrastructure variable
export TF_VAR_TAILSCALE_HOST="your-tailscale-fqdn"

# Plan & apply
terraform plan
terraform apply
```

> **Note:** App and service secrets are no longer passed via `TF_VAR_` variables. They are fetched at runtime by ESO from Doppler. The `doppler_service_tokens` variable in `4-eso.tf` can be used to define which Doppler projects/configs should have service tokens created for ESO to reference.

After apply, ArgoCD will be available at `localhost:8080`:
```bash
kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80
```

The initial ArgoCD password is the auto-generated pod name:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Project Structure

```
.
├── 1-k8s.tf                      # Minikube cluster + CoreDNS hardening
├── 2-managed_services.tf         # ArgoCD Helm release
├── 3-gitops.tf                   # App-of-Apps manifests
├── 4-eso.tf                     # ESO + Doppler bootstrap (service tokens → K8s Secrets)
├── variables.tf                  # All input variables
├── outputs.tf                    # Kubeconfig output with Tailscale endpoint
├── versions.tf                   # Provider versions + Terraform Cloud config
├── helm/
│   └── argocd-values.yaml        # ArgoCD Helm overrides
├── argocd_app-of-apps/
│   ├── services.yml              # Application template for 3rd-party services
│   └── apps.yml                  # Application template for my own workloads
└── README.md
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.19.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.22.0 |
| <a name="requirement_minikube"></a> [minikube](#requirement\_minikube) | >= 0.6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_minikube"></a> [minikube](#provider\_minikube) | 0.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.coredns_config](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.coredns_deployment](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.coredns_hpa](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.coredns_pdb](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.services](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [minikube_cluster.maklab_cluster](https://registry.terraform.io/providers/scott-the-programmer/minikube/latest/docs/resources/cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_DOPPLER_PROD_TOKEN"></a> [DOPPLER\_PROD\_TOKEN](#input\_DOPPLER\_PROD\_TOKEN) | Doppler var - App Access token to Doppler for PROD | `any` | n/a | yes |
| <a name="input_DOPPLER_STAGING_TOKEN"></a> [DOPPLER\_STAGING\_TOKEN](#input\_DOPPLER\_STAGING\_TOKEN) | Doppler var - App Access token to Doppler for staging | `any` | n/a | yes |
| <a name="input_GRAFANA_ADMIN"></a> [GRAFANA\_ADMIN](#input\_GRAFANA\_ADMIN) | Doppler var - Grafana admin username | `any` | n/a | yes |
| <a name="input_GRAFANA_PW"></a> [GRAFANA\_PW](#input\_GRAFANA\_PW) | Doppler var - Grafana admin password | `any` | n/a | yes |
| <a name="input_MONGODB_HOST"></a> [MONGODB\_HOST](#input\_MONGODB\_HOST) | MongoDB host for service access | `any` | n/a | yes |
| <a name="input_MONGODB_PW"></a> [MONGODB\_PW](#input\_MONGODB\_PW) | MongoDB password for service access | `any` | n/a | yes |
| <a name="input_MONGODB_USER"></a> [MONGODB\_USER](#input\_MONGODB\_USER) | MongoDB user for service access | `any` | n/a | yes |
| <a name="input_PG_PW"></a> [PG\_PW](#input\_PG\_PW) | Doppler var - Postgres password for app access | `any` | n/a | yes |
| <a name="input_PG_USER"></a> [PG\_USER](#input\_PG\_USER) | Doppler var - Postgres user for app access | `any` | n/a | yes |
| <a name="input_TAILSCALE_HOST"></a> [TAILSCALE\_HOST](#input\_TAILSCALE\_HOST) | URL to Tailscale Tunnel | `any` | n/a | yes |
| <a name="input_cluster_config"></a> [cluster\_config](#input\_cluster\_config) | Cluster-wide configuration for the minikube cluster | `map(string)` | <pre>{<br/>  "cni": "flannel",<br/>  "container_runtime": "containerd",<br/>  "driver": "krunkit"<br/>}</pre> | no |
| <a name="input_gitops_apps_path"></a> [gitops\_apps\_path](#input\_gitops\_apps\_path) | Path to ArgoCD App manifests for Apps | `string` | `"apps/argocd-appset"` | no |
| <a name="input_gitops_branch"></a> [gitops\_branch](#input\_gitops\_branch) | Branch to follow for GitOps deployment | `string` | `"HEAD"` | no |
| <a name="input_gitops_repo"></a> [gitops\_repo](#input\_gitops\_repo) | Where GitOps Helm charts are stored | `string` | `"https://github.com/jomakori/gke_GitOps.git"` | no |
| <a name="input_gitops_services_path"></a> [gitops\_services\_path](#input\_gitops\_services\_path) | Path to ArgoCD App manifests for Services | `string` | `"services/argocd-appset"` | no |
| <a name="input_k8s_cidr_ranges"></a> [k8s\_cidr\_ranges](#input\_k8s\_cidr\_ranges) | Mapping of CIDR ranges for K8s pods + services | `map(any)` | <pre>{<br/>  "pods": "10.0.0.0/16",<br/>  "services": "127.0.0.0/16"<br/>}</pre> | no |
| <a name="input_k8s_config_path"></a> [k8s\_config\_path](#input\_k8s\_config\_path) | Kubernetes config file path | `string` | `"~/.kube/config"` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version to use for k8s cluster. For latest version, run `minikube config defaults kubernetes-version` | `string` | `"v1.35.1"` | no |
| <a name="input_name"></a> [name](#input\_name) | Namespace for workspace resources | `string` | `"jmak-lab"` | no |
| <a name="input_vm_config"></a> [vm\_config](#input\_vm\_config) | VM resource settings for minikube cluster nodes | `map(string)` | <pre>{<br/>  "cpus": "max",<br/>  "disk_size": "10000mb",<br/>  "memory": "15g",<br/>  "worker_nodes": "4"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig for accessing the minikube cluster via Tailscale tunnel |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

# k8s-maklab-cluster

Terraform-managed local Minikube Kubernetes cluster for the **jmak-lab** environment, deployed via the krunkit driver on macOS and orchestrated entirely through ArgoCD GitOps.

## Architecture & Flow

```
1-k8s.tf               ← provisions the Minikube cluster (v1.35.1, 4 workers, flannel CNI, containerd)
                            CoreDNS hardened: resource bounds, HPA (2-6 replicas), anti-affinity, PDB
                            Tailscale FQDN for remote API access

2-eso.tf               ← creates external-secrets namespace + stores Doppler personal token as K8s Secret
                            ClusterSecretStores in the GitOps repo reference this token with their own project+config

3-managed_services.tf  ← installs ArgoCD (helm_release.argocd) — ArgoCD can't manage itself

4-gitops.tf            ← creates "services" ArgoCD Application via App-of-Apps pattern
                            Points at gke_GitOps repo → ArgoCD auto-syncs (prune + self-heal)
```

### Structure

```
.
├── 1-k8s.tf                  # Cluster provisioning
├── 2-eso.tf                  # ESO bootstrap — namespace + token secret
├── 3-managed_services.tf     # ArgoCD installation
├── 4-gitops.tf               # App-of-Apps manifests
├── variables.tf              # cluster_config, gitops_config, DOPPLER_TOKEN, TAILSCALE_HOST
├── outputs.tf                # Kubeconfig with Tailscale endpoint
├── versions.tf               # Provider versions + Terraform Cloud config
├── helm/
│   └── argocd-values.yaml    # ArgoCD Helm overrides
└── argocd_app-of-apps/
    ├── services.yml          # Application template for 3rd-party services
    └── apps.yml              # Application template for app workloads
```

## Secrets

No app/service secrets pass through Terraform variables or `terraform.tfvars`. Everything flows through ESO + Doppler:

1. Terraform stores `var.DOPPLER_TOKEN` (personal token) as a K8s Secret in `external-secrets`.
2. ClusterSecretStore resources in the GitOps repo reference that token with their `project` + `config`.
3. ExternalSecrets use `dataFrom.extract` with zero rewrite rules — K8s Secret keys match Doppler key names. `refreshInterval: 1m`.
4. Pods consume via standard `secretKeyRef`.

| Variable | Source | Used By |
|----------|--------|---------|
| `TAILSCALE_HOST` | Tailscale (`TF_VAR_`) | Cluster API server FQDN |
| `DOPPLER_TOKEN` | Doppler personal token (`TF_VAR_`) | ESO bootstrap K8s Secret |

## Usage

```bash
# Prerequisites: Terraform >= 1.6, Minikube + krunkit, Tailscale, Doppler CLI
terraform login
export TF_VAR_TAILSCALE_HOST="your-tailscale-fqdn"
export TF_VAR_DOPPLER_TOKEN="dp.ct.your-personal-token"

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

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_doppler"></a> [doppler](#requirement\_doppler) | >= 1.21.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.19.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.22.0 |
| <a name="requirement_minikube"></a> [minikube](#requirement\_minikube) | >= 0.6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.22.0 |
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
| [kubectl_manifest.doppler_machine_token_secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.eso_namespace](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.services](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [minikube_cluster.maklab_cluster](https://registry.terraform.io/providers/scott-the-programmer/minikube/latest/docs/resources/cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_DOPPLER_TOKEN"></a> [DOPPLER\_TOKEN](#input\_DOPPLER\_TOKEN) | Doppler personal token for ESO ClusterSecretStore bootstrap | `string` | n/a | yes |
| <a name="input_TAILSCALE_HOST"></a> [TAILSCALE\_HOST](#input\_TAILSCALE\_HOST) | Tailscale FQDN for remote cluster access | `any` | n/a | yes |
| <a name="input_cluster_config"></a> [cluster\_config](#input\_cluster\_config) | Cluster-wide configuration for the minikube cluster | `map(string)` | <pre>{<br/>  "cni": "flannel",<br/>  "container_runtime": "containerd",<br/>  "cpus": "max",<br/>  "disk_size": "10000mb",<br/>  "driver": "krunkit",<br/>  "kubernetes_version": "v1.35.1",<br/>  "memory": "15g",<br/>  "name": "jmak-lab",<br/>  "worker_nodes": "4"<br/>}</pre> | no |
| <a name="input_gitops_config"></a> [gitops\_config](#input\_gitops\_config) | GitOps configuration passed to ArgoCD App-of-Apps Helm values | `map(string)` | <pre>{<br/>  "apps_path": "apps/argocd-appset",<br/>  "argoNamespace": "argocd",<br/>  "argoProject": "default",<br/>  "clusterDomain": "maklab.net",<br/>  "clusterServer": "https://kubernetes.default.svc",<br/>  "repo": "https://github.com/jomakori/gke_GitOps.git",<br/>  "services_path": "services/argocd-appset",<br/>  "storageClass": "local-path",<br/>  "targetRevision": "HEAD"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig for accessing the minikube cluster via Tailscale tunnel |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

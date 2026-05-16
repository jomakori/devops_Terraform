# k8s-maklab-cluster

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

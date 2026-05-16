# gke_GitOps_oriented-cluster

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.17.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.17.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.19.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.22.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 6.36.1 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_gke"></a> [gke](#module\_gke) | terraform-google-modules/kubernetes-engine/google | >= 35.0.1 |
| <a name="module_network"></a> [network](#module\_network) | terraform-google-modules/network/google | >= 7.5 |

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.apps](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.services](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_DOPPLER_PROD_TOKEN"></a> [DOPPLER\_PROD\_TOKEN](#input\_DOPPLER\_PROD\_TOKEN) | Doppler var - App Access token to Doppler for PROD | `any` | n/a | yes |
| <a name="input_DOPPLER_STAGING_TOKEN"></a> [DOPPLER\_STAGING\_TOKEN](#input\_DOPPLER\_STAGING\_TOKEN) | Doppler var - App Access token to Doppler for staging | `any` | n/a | yes |
| <a name="input_NOTES_APP_PG_PW"></a> [NOTES\_APP\_PG\_PW](#input\_NOTES\_APP\_PG\_PW) | Doppler var - Postgres password for Notes app | `any` | n/a | yes |
| <a name="input_NOTES_APP_PG_USER"></a> [NOTES\_APP\_PG\_USER](#input\_NOTES\_APP\_PG\_USER) | Doppler var - Postgres user for Notes app | `any` | n/a | yes |
| <a name="input_WHITELIST_K8S_ACCESS"></a> [WHITELIST\_K8S\_ACCESS](#input\_WHITELIST\_K8S\_ACCESS) | Doppler var - List of IP addresses to whitelist for access to the cluster | `map(string)` | n/a | yes |
| <a name="input_gitops_apps_path"></a> [gitops\_apps\_path](#input\_gitops\_apps\_path) | Path to ArgoCD App manifests for Apps | `string` | `"apps/argocd-appset"` | no |
| <a name="input_gitops_branch"></a> [gitops\_branch](#input\_gitops\_branch) | Branch to follow for GitOps deployment | `string` | `"HEAD"` | no |
| <a name="input_gitops_repo"></a> [gitops\_repo](#input\_gitops\_repo) | Where GitOps Helm charts are stored | `string` | `"https://github.com/jomakori/gke_GitOps.git"` | no |
| <a name="input_gitops_services_path"></a> [gitops\_services\_path](#input\_gitops\_services\_path) | Path to ArgoCD App manifests for Services | `string` | `"services/argocd-appset"` | no |
| <a name="input_k8s_cidr_ranges"></a> [k8s\_cidr\_ranges](#input\_k8s\_cidr\_ranges) | Mapping of CIDR ranges for K8s pods + services | `map(any)` | <pre>{<br/>  "control-plane": "172.16.0.0/28",<br/>  "pods": "192.168.0.0/16",<br/>  "services": "192.169.0.0/16"<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Namespace for workspace resources | `string` | `"gitops-k8s-cluster"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google Account/Project ID | `string` | `"absolute-cipher-449014-p0"` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region for resources | `string` | `"us-central1"` | no |
| <a name="input_subnet_cidr_ranges"></a> [subnet\_cidr\_ranges](#input\_subnet\_cidr\_ranges) | Mapping of CIDR ranges for VPC networking | `map(string)` | <pre>{<br/>  "subnet-a": "10.0.0.0/16",<br/>  "subnet-b": "10.1.0.0/16"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_get_credentials_command"></a> [get\_credentials\_command](#output\_get\_credentials\_command) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

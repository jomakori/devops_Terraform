# EKS - Commerce Engine K8s Cluster

This subfolder contains the Terraform configuration for deploying and managing a Kubernetes cluster on Amazon EKS and its dependency components, including:
- VPC + other networking components
- VPC Peering connection + whitelisting for access to RDS + Redis
- EKS Cluster, Node Group, AWS Plugins
- GitOps Configuration - via ArgoCD
  - Deploys/Manages ArgoCD - Service used to sync our apps/services in cluster, [the GitOps way](https://github.com/richcontext/kubernetes)
  - Manages Service Accounts
  - Manages Services - like External Secrets, AWS ALB Controller etc
  - Manages our Applicatons - like demo_app, etc

## Directory Structure

### `argocd_app-of-apps` folder

This directory contains ArgoCD configurations for managing applications and services [via the "App of Apps" pattern.](https://aws.amazon.com/blogs/containers/bootstrapping-clusters-with-eks-blueprints/)

- `apps.yml`: Defines the applications to be managed by ArgoCD.
- `services.yml`: Defines the services to be managed by ArgoCD.

### `provisioners` Folder

This directory contains YAML files for provisioning various components and services in the cluster.
These are manual k8s manifests that can't be deployed via Helm

- `0-datadog_secrets.yml`: Configuration for Datadog secrets.
- `1-karpenter_nodepool.yml`: Configuration for Karpenter node pool.
- `2-karpenter_nodeclass.yml`: Configuration for Karpenter node class.
- `3-datadog_agent.yml`: Configuration for Datadog agent deployment.

### Terraform Templates

- `1-vpc.tf`: Defines the Virtual Private Cloud (VPC) setup.
- `2-vpc_peering.tf`: Manages VPC peering connections.
- `3-eks.tf`: Configuration for the EKS cluster, its nodes and its user access
- `4-gitops_deps.tf`: Dependencies required for GitOps
  - ArgoCD repo access + manual k8s manifests
- `5-gitops.tf`: GitOps-related configurations
  - Deployment of services, apps and its components (service accounts, provisioners, etc) 
- `outputs.tf`: Outputs from the Terraform configurations.
- `variables.tf`: Variables used in the Terraform configurations.
- `versions.tf`: Specifies the required Terraform version and providers.

### Other Files

- `Makefile`: Defines make commands for managing the project
- `argocd-values.yaml`: Values file for configuring ArgoCD via Helm

## Makefile Commands

> **IMPORTANT: Always deploy changes via the pipeline.** Only use this for performing fixes on the EKS cluster and its configuration. Consult the team before performing such changes.

### Apply Commands

- `make apply`
  - **Usage:** Apply ongoing changes
  - Commonly used

- `make apply_mass`
  - **Usage:** Apply changes gracefully

- `make apply_vpc`, `make apply_vpc_peering`, `make apply_eks`, `apply_eks_addons`, `apply_argocd`, `apply_services`, `apply_apps`
  - **Usage:** Silo target & Apply changes to specific modules individually.

### Destroy Commands

- `make destroy_mass`
  - **Usage:** Destroy resources gracefully in specific order to avoid issues.

- `make destroy_apps`, `make destroy_services`, `make destroy_argocd`,  `make destroy_eks_addons`, `make destroy_eks`, `make destroy_vpc_peering`, `make destroy_vpc`
  - **Usage:** Silo target & Destroy changes to specific modules individually.


## Monitor GitOps health status
Confirm all the ArgoCD applications `HEALTH STATUS` is `Healthy`. Use Crl+C to exit the `watch` command
```shell
watch kubectl get applications -n argocd
```
> **Note:** You can also confirm this by opening ArgoCD

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_argocd"></a> [argocd](#requirement\_argocd) | >= 6.0.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.67.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.22.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.3.2 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.67.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.10.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.14.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_eks"></a> [eks](#module\_eks) | cloudposse/eks-cluster/aws | 4.1.0 |
| <a name="module_eks_blueprints_addons"></a> [eks\_blueprints\_addons](#module\_eks\_blueprints\_addons) | aws-ia/eks-blueprints-addons/aws | n/a |
| <a name="module_eks_node_group"></a> [eks\_node\_group](#module\_eks\_node\_group) | cloudposse/eks-node-group/aws | 2.12.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.7.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_security_group_rule.cluster_sg_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.dns_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.http_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.https_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lb_http_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lb_https_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.service_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [helm_release.argocd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.apps](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.services](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_security_groups.k8s_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_groups) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_vpc_cidr_block"></a> [aws\_vpc\_cidr\_block](#input\_aws\_vpc\_cidr\_block) | The VPC cidr block for EKS | `string` | `"172.81.0.0/16"` | no |
| <a name="input_aws_vpc_enable_dns_hostnames"></a> [aws\_vpc\_enable\_dns\_hostnames](#input\_aws\_vpc\_enable\_dns\_hostnames) | n/a | `bool` | `true` | no |
| <a name="input_aws_vpc_enable_dns_support"></a> [aws\_vpc\_enable\_dns\_support](#input\_aws\_vpc\_enable\_dns\_support) | n/a | `bool` | `true` | no |
| <a name="input_aws_vpc_instance_tenancy"></a> [aws\_vpc\_instance\_tenancy](#input\_aws\_vpc\_instance\_tenancy) | n/a | `string` | `"default"` | no |
| <a name="input_aws_vpc_tc_category"></a> [aws\_vpc\_tc\_category](#input\_aws\_vpc\_tc\_category) | n/a | `string` | `"vpc"` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | n/a | `list(string)` | <pre>[<br/>  "us-east-2a",<br/>  "us-east-2b",<br/>  "us-east-2c"<br/>]</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Type of Deployment | `string` | `"Production"` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | Kubernetes Version for EKS. | `string` | `"1.31"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of Deployment | `string` | `"jm-k8s"` | no |
| <a name="input_rds_db_securitygroup"></a> [rds\_db\_securitygroup](#input\_rds\_db\_securitygroup) | n/a | `string` | `"sg-550efa3d"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"us-east-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | <pre>{<br/>  "deployment": "jm-k8s-cluster",<br/>  "environment": "Production"<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

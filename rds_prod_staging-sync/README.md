# rds-db-production

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_demo"></a> [demo](#provider\_demo) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_demo_app_prod_db_cluster"></a> [demo\_app\_prod\_db\_cluster](#module\_demo\_app\_prod\_db\_cluster) | cloudposse/rds-cluster/aws | 1.9.0 |
| <a name="module_demo_app_staging_db_cluster"></a> [demo\_app\_staging\_db\_cluster](#module\_demo\_app\_staging\_db\_cluster) | cloudposse/rds-cluster/aws | 1.9.0 |
| <a name="module_shared_rds_sg"></a> [shared\_rds\_sg](#module\_shared\_rds\_sg) | terraform-aws-modules/security-group/aws | 4.1.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.7.1 |
| <a name="module_vpc_peering"></a> [vpc\_peering](#module\_vpc\_peering) | cloudposse/vpc-peering/aws | >= 1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route.rds_routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [null_resource.update_doppler_endpoint](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [demo_app_rds_prod_snapshot.latest_snapshot](https://registry.terraform.io/providers/hashicorp/demo/latest/docs/data-sources/app_rds_prod_snapshot) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ACN_MODULES_TOKEN"></a> [ACN\_MODULES\_TOKEN](#input\_ACN\_MODULES\_TOKEN) | n/a | `string` | n/a | yes |
| <a name="input_DB_PASSWORD"></a> [DB\_PASSWORD](#input\_DB\_PASSWORD) | n/a | `string` | n/a | yes |
| <a name="input_DB_USER"></a> [DB\_USER](#input\_DB\_USER) | n/a | `string` | n/a | yes |
| <a name="input_DOPPLER_PROD_TOKEN"></a> [DOPPLER\_PROD\_TOKEN](#input\_DOPPLER\_PROD\_TOKEN) | n/a | `string` | n/a | yes |
| <a name="input_DOPPLER_STAGING_TOKEN"></a> [DOPPLER\_STAGING\_TOKEN](#input\_DOPPLER\_STAGING\_TOKEN) | n/a | `string` | n/a | yes |
| <a name="input_aws_eks_cidr_block"></a> [aws\_eks\_cidr\_block](#input\_aws\_eks\_cidr\_block) | The VPC cidr block for EKS | `string` | `"172.81.0.0/16"` | no |
| <a name="input_aws_eks_vpc_id"></a> [aws\_eks\_vpc\_id](#input\_aws\_eks\_vpc\_id) | The VPC ID for EKS | `string` | `"vpc-0d21a956acd69aa75"` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | The RDS Engine Type | `string` | `"aurora-postgresql"` | no |
| <a name="input_logging_type"></a> [logging\_type](#input\_logging\_type) | The type of RDS logs to record in CloudWatch | `list` | <pre>[<br/>  "stderr"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name of Deployment | `string` | `"demo_app-rds"` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | Postgres Version of the RDS Cluster | `string` | `"15.4"` | no |
| <a name="input_postgres_version_class"></a> [postgres\_version\_class](#input\_postgres\_version\_class) | Dependent of postgres version: | `string` | `"aurora-postgresql15"` | no |
| <a name="input_rds_enforce_ssl"></a> [rds\_enforce\_ssl](#input\_rds\_enforce\_ssl) | Enforce SSL for RDS | `list` | <pre>[<br/>  {<br/>    "apply_method": "pending-reboot",<br/>    "name": "rds.force_ssl",<br/>    "value": "0"<br/>  }<br/>]</pre> | no |
| <a name="input_rds_tags"></a> [rds\_tags](#input\_rds\_tags) | n/a | `map(string)` | <pre>{<br/>  "usage": "Deployment of the Commerce Engine RDS cluster - Staging + Prod"<br/>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"us-east-2"` | no |
| <a name="input_scaling_mode"></a> [scaling\_mode](#input\_scaling\_mode) | Server based or serverless | `string` | `"provisioned"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | The CIDR block used for this deployment | `string` | `"172.11.0.0/16"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

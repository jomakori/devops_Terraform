# ec2_tower
## **Description**

This Terraform workspace is designed to automate the setup of Amazon EC2 instances with monitoring tools pre-installed. The monitoring tools are fetched from an Amazon S3 bucket. The users can separate their deployments using multiple .tf files or they can keep it in another relevant workspace.

---

## **Prerequisites**

- Terraform v0.12 or later
- AWS CLI v2
- An AWS account with the necessary permissions

---

## **Setup and Usage**

### 1. Copy an existing setup in workspace. 
Make sure to adjust template for your setup. Our monitoring & custom tools are setup in the `tower-acn-compliance-artifacts` S3 bucket on the Tower account, seperated by OS: `Linux` or `Windows`. Edit the `user_data` attribute within the EC2 module to setup up tools, based on your OS.

### 2. Initialize your Terraform workspace & validate your files

```bash
terraform init && terraform validate
```

### 3. Confirm Changes - via Doppler
This will show you what actions Terraform will take without making any real changes.

```bash
doppler setup -p devops -c ci               # passes devops ci env vars 
doppler run --command='terraform plan'
```

### 4. If everything looks good, open a PR to plan/apply the changes 


## **Notes**

- Be sure to separate out your deployments into different .tf files or contain them in another relevant workspace to avoid any potential conflicts and maintain organization.

---
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.68.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_compliance_bucket"></a> [compliance\_bucket](#module\_compliance\_bucket) | terraform-aws-modules/s3-bucket/aws | n/a |
| <a name="module_ec2-ami-snapshot"></a> [ec2-ami-snapshot](#module\_ec2-ami-snapshot) | cloudposse/backup/aws | n/a |
| <a name="module_ec2-gateways"></a> [ec2-gateways](#module\_ec2-gateways) | cloudposse/ec2-instance/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.compliance_bucket_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_key_pair.pubkey](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_s3_object.linux_scripts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.windows_scripts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_secretsmanager_secret.privkey](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.privkey_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.gateway_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [tls_private_key.ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.gateway_pub_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.gateway_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_POWERBI_CLIENT_ID"></a> [POWERBI\_CLIENT\_ID](#input\_POWERBI\_CLIENT\_ID) | PowerBI Credentials for script | `any` | n/a | yes |
| <a name="input_POWERBI_CLIENT_SECRET"></a> [POWERBI\_CLIENT\_SECRET](#input\_POWERBI\_CLIENT\_SECRET) | PowerBI Credentials for script | `any` | n/a | yes |
| <a name="input_POWERBI_RECOVER_KEY"></a> [POWERBI\_RECOVER\_KEY](#input\_POWERBI\_RECOVER\_KEY) | PowerBI Credentials for script | `any` | n/a | yes |
| <a name="input_POWERBI_TENANT_ID"></a> [POWERBI\_TENANT\_ID](#input\_POWERBI\_TENANT\_ID) | PowerBI Credentials for script | `any` | n/a | yes |
| <a name="input_TOWER_ACCESS_KEY"></a> [TOWER\_ACCESS\_KEY](#input\_TOWER\_ACCESS\_KEY) | AWS Access Key - Tower | `any` | n/a | yes |
| <a name="input_TOWER_ACCESS_SECRET"></a> [TOWER\_ACCESS\_SECRET](#input\_TOWER\_ACCESS\_SECRET) | AWS Access Secret - Tower | `any` | n/a | yes |
| <a name="input_TOWER_REGION"></a> [TOWER\_REGION](#input\_TOWER\_REGION) | AWS Region - Tower | `any` | n/a | yes |
| <a name="input_gateway_az"></a> [gateway\_az](#input\_gateway\_az) | Availability zone for the EC2 Gateway | `string` | `"us-west-2b"` | no |
| <a name="input_gateway_environments"></a> [gateway\_environments](#input\_gateway\_environments) | EC2 Gateway environments | `list` | <pre>[<br>  "prod",<br>  "staging"<br>]</pre> | no |
| <a name="input_gateway_name"></a> [gateway\_name](#input\_gateway\_name) | Naming Strategy for Gateway resources | `string` | `"katana-reporting"` | no |
| <a name="input_gateway_tags"></a> [gateway\_tags](#input\_gateway\_tags) | n/a | `map` | <pre>{<br>  "managed_by": "terraform",<br>  "usage": "EC2 Gateway - for Katana Reporting"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_pem_keys"></a> [gateway\_pem\_keys](#output\_gateway\_pem\_keys) | Access PEM key via Secrets Manager - used to unveil password |
| <a name="output_gateway_public_ips"></a> [gateway\_public\_ips](#output\_gateway\_public\_ips) | Public IPs for the EC2 Gateways |
| <a name="output_gateway_user"></a> [gateway\_user](#output\_gateway\_user) | Login Username for RDP |
| <a name="output_powerbi_vars"></a> [powerbi\_vars](#output\_powerbi\_vars) | PowerBI information |
<!-- END_TF_DOCS -->

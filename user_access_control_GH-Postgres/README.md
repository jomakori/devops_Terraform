# User Access Control Manager

This Terraform script allows for managing users and their access to GitHub repositories and RDS databases.

## Configuration

The script uses a CSV file to store information about users. To set up, you need to create a CSV file with the following columns:

- `Accenture_UID`: your Accenture ID w/ modification - used as the Postgres username.
- `GITHUB_USER`: the user's GitHub username.
- `GITHUB_ROLE`: the user's role in GitHub (either "admin,maintainer" or "member").

## Adding/changing a User

To add/change a user, follow these steps:

1. Add a new/edit row on the CSV file with the user's information. Save the changes in a new `feature branch`

2. Run `terraform init` to initialize Terraform in your project.

3. Run `terraform plan` to review the changes. 

4. Commit changes to github, to re-confirm and apply changes

## Removing a User

To remove a user, follow these steps:

1. Remove the user's row from the CSV file. Save the changes in a new `feature branch`

2. Run `terraform init` to initialize Terraform in your project.

3. Run `terraform plan` to review the changes.  

4. Commit changes to github, to re-confirm and apply changes

## Password Rotation

Passwords are managed by Terraform using the `random_password` resource. When a user is added, Terraform generates a random password and stores it securely in Doppler.

### To rotate a user's password:

1. Run `terraform taint 'random_password.postgres_pw["USERNAME"]'`, replacing "USERNAME" with the user's username. This marks the password as needing to be recreated.

2. Run `terraform apply` to apply the changes locally (since the code hasn't changed). Terraform will generate a new password and update it in the Postgres database.

Remember, Terraform manages the state of your infrastructure, so any changes should be made through Terraform, not manually. This ensures that the state of your infrastructure stays in sync with your Terraform configuration.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_doppler"></a> [doppler](#requirement\_doppler) | >= 1.9.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 5.0 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | >= 1.22.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_doppler.production"></a> [doppler.production](#provider\_doppler.production) | >= 1.9.0 |
| <a name="provider_doppler.staging"></a> [doppler.staging](#provider\_doppler.staging) | >= 1.9.0 |
| <a name="provider_github"></a> [github](#provider\_github) | >= 5.0 |
| <a name="provider_postgresql.production"></a> [postgresql.production](#provider\_postgresql.production) | >= 1.22.0 |
| <a name="provider_postgresql.staging"></a> [postgresql.staging](#provider\_postgresql.staging) | >= 1.22.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [doppler_secret.production_postgres_creds](https://registry.terraform.io/providers/DopplerHQ/doppler/latest/docs/resources/secret) | resource |
| [doppler_secret.staging_postgres_creds](https://registry.terraform.io/providers/DopplerHQ/doppler/latest/docs/resources/secret) | resource |
| [github_membership.org_membership](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/membership) | resource |
| [github_team_membership.team_membership](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_membership) | resource |
| [postgresql_grant.production_postgres_user_grant](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_grant.staging_postgres_user_grant](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_role.production_postgres_user](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [postgresql_role.staging_postgres_user](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [random_password.postgres_pw](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [github_team.engineering](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/team) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_AWS_ACCOUNT_ID"></a> [AWS\_ACCOUNT\_ID](#input\_AWS\_ACCOUNT\_ID) | AWS Account ID | `any` | n/a | yes |
| <a name="input_AWS_REGION"></a> [AWS\_REGION](#input\_AWS\_REGION) | Default AWS Region | `any` | n/a | yes |
| <a name="input_DB_NAME"></a> [DB\_NAME](#input\_DB\_NAME) | Demo\_App db | `any` | n/a | yes |
| <a name="input_DB_PASSWORD"></a> [DB\_PASSWORD](#input\_DB\_PASSWORD) | Demo\_App Admin | `any` | n/a | yes |
| <a name="input_DB_USER"></a> [DB\_USER](#input\_DB\_USER) | Demo\_App Admin | `any` | n/a | yes |
| <a name="input_DOPPLER_PROD_TOKEN"></a> [DOPPLER\_PROD\_TOKEN](#input\_DOPPLER\_PROD\_TOKEN) | The Doppler cred for Demo\_App - Production | `any` | n/a | yes |
| <a name="input_DOPPLER_STAGING_TOKEN"></a> [DOPPLER\_STAGING\_TOKEN](#input\_DOPPLER\_STAGING\_TOKEN) | The Doppler cred for Demo\_App - Staging | `any` | n/a | yes |
| <a name="input_GITHUB_TOKEN"></a> [GITHUB\_TOKEN](#input\_GITHUB\_TOKEN) | GitHub Token for Robopony | `any` | n/a | yes |
| <a name="input_PROD_DB_HOST"></a> [PROD\_DB\_HOST](#input\_PROD\_DB\_HOST) | Postgres host - Production | `any` | n/a | yes |
| <a name="input_STAGING_DB_HOST"></a> [STAGING\_DB\_HOST](#input\_STAGING\_DB\_HOST) | Postgres host - Production | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_doppler_production_creds"></a> [doppler\_production\_creds](#output\_doppler\_production\_creds) | n/a |
| <a name="output_doppler_staging_creds"></a> [doppler\_staging\_creds](#output\_doppler\_staging\_creds) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

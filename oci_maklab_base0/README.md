# OCI ARM VM with Tailscale Integration

Security-first ARM VM deployment on OCI Free Tier with automated Tailscale integration using Tailscale's official Terraform module and 90-day key rotation.

## 📋 Features

- **Maxed-out OCI Free Tier**: 4 ARM vCPU, 24GB RAM, 200GB storage
- **Latest Fedora OS**: ARM-optimized Fedora image
- **Tailscale VPN**: Secure access with 90-day rotatable auth keys
- **Official Tailscale Terraform Module**: Uses `terraform-cloudinit-tailscale` module for cloud-init
- **Doppler Secrets**: Centralized secret management (Terraform-side only)
- **Automated Key Rotation**: GitHub Actions workflow every 85 days
- **Structured Logging**: OCI Logging with JSON format
- **Security-First**: Minimal public exposure, Tailscale-only access, auth key embedded at apply time

## 🏗️ Architecture

```
OCI Free Tier → VCN → ARM VM → Tailscale → Secure Access
       ↓           ↓         ↓         ↓
  4 vCPU    Public/Private  Fedora  90-day
  24GB RAM    Subnets        OS     Rotation
  200GB Storage            Cloud-init
```

## 📁 File Structure

```
oci_maklab_base0/
├── versions.tf          # Provider versions
├── variables.tf         # Secret values and repeated values
├── providers.tf         # Provider configurations
├── 1-vm.tf              # All infrastructure resources
├── data.tf              # Data sources for OCI images
├── outputs.tf           # Connection details
├── Makefile             # Convenience commands
└── README.md            # This file
```

### Tailscale Integration

This project uses Tailscale's official open-source Terraform module [`terraform-cloudinit-tailscale`](https://github.com/tailscale/terraform-cloudinit-tailscale) for cloud-init configuration. This approach:

1. **Generates cloud-init at apply time**: The auth key is embedded directly into the cloud-init configuration
2. **No runtime secret retrieval**: The VM doesn't need Doppler CLI installed to fetch secrets
3. **Official Tailscale module**: Uses Tailscale's maintained cloud-init module
4. **Zero custom scripts**: No manual shell scripts required - the module handles everything

The `terraform-cloudinit-tailscale` module generates a complete cloud-init configuration that:
- Installs Tailscale using the official package repository
- Authenticates with the provided auth key
- Configures hostname, exit node advertising, and route acceptance
- Handles all OS-specific installation details

## 🚀 Deployment

### Prerequisites

1. **OCI Account**: Free tier account with API credentials
2. **Tailscale Account**: API key for auth key generation
3. **Doppler Account**: Token for secret management (Terraform-side only)
4. **Terraform CLI**: Version 1.5.0 or later
5. **Doppler CLI**: For secret injection during Terraform operations

### Setup Doppler Secrets

Configure Doppler with required secrets using the CLI:

```bash
# 1. Get OCI Tenancy OCID (requires OCI CLI login)
oci session authenticate --profile-name DEFAULT
oci iam tenancy get --query 'data."id"' --raw-output

# 2. Set OCI secrets in Doppler
doppler run --project devops --config ci -- doppler secrets set OCI_TENANCY_OCID="<tenancy-ocid>"
doppler run --project devops --config ci -- doppler secrets set OCI_USER_OCID="<user-ocid>"
doppler run --project devops --config ci -- doppler secrets set OCI_FINGERPRINT="<fingerprint>"
doppler run --project devops --config ci -- doppler secrets set OCI_PRIVATE_KEY="<private-key-content>"

# 3. Set Tailscale API key (if not already set)
doppler run --project devops --config ci -- doppler secrets set TAILSCALE_API_KEY="tskey-..."

# 4. Verify secrets are set
doppler run --project devops --config ci -- env | grep TF_VAR
```

**Note**: The Doppler project is `devops` and config is `ci`. Adjust as needed for your setup.

### Deploy Infrastructure

```bash
cd oci_maklab_base0

# Initialize Terraform
doppler run -- terraform init

# Plan deployment
doppler run -- terraform plan

# Apply deployment
doppler run -- terraform apply
```

### Using Makefile

```bash
# Initialize
make init

# Plan changes
make plan

# Apply changes
make apply

# Destroy infrastructure
make destroy

# Rotate Tailscale key manually
make rotate
```

## 🔐 Security

### Network Security
- VCN with public/private subnets (10.0.0.0/16)
- Security lists restrict ingress to SSH, HTTP, HTTPS
- Public IP assigned for initial setup only
- Primary access via Tailscale VPN

### Access Control
- **Tailscale Authentication**: Device-based with rotatable keys
- **90-Day Key Rotation**: Automatic via GitHub Actions
- **OCI IAM**: Instance principal for API access
- **No SSH Keys**: SSH access via Tailscale only

### Secret Management
- Secrets stored in Doppler (not in Terraform state)
- Terraform retrieves secrets via `doppler run --`
- GitHub Actions uses Doppler token for automation

## 🔄 Key Rotation

### Automatic Rotation
- GitHub Actions workflow runs every 85 days
- Generates new Tailscale auth key via API
- Updates Doppler secret automatically
- Annotates workflow with reboot instructions

### Manual Rotation
```bash
# Rotate key manually
make rotate

# Plan rotation only
doppler run -- terraform plan -target=tailscale_key.vm_auth_key
```

### Emergency Access
If key rotation fails:
1. Use OCI Serial Console (no network required)
2. Navigate to OCI Console → Compute → Instances
3. Select VM → "Serial Console Connection"
4. Manually reconnect Tailscale:
   ```bash
   sudo tailscale up --authkey=$(doppler secrets get TAILSCALE_AUTH_KEY --plain)
   ```

## 📊 Verification

### Check Deployment
```bash
# View Terraform outputs
doppler run -- terraform output

# Check Tailscale connection
tailscale status

# SSH via Tailscale
ssh fedora@maklab-base0-vm.tailnet-name.ts.net
```

### View Logs

The OCI Logging module (`oracle-terraform-modules/logging/oci`) is configured to collect Tailscale installation logs:

```bash
# View logs in OCI Console
# Navigate to: Observability & Management → Logging → Log Groups → maklab-base0-tailscale-logs

# Search logs via OCI CLI
oci logging-search search-logs \
  --search-query "search \"${var.OCI_TENANCY_OCID}/${var.name}-tailscale-logs\" | where component = 'tailscale'" \
  --time-start 2024-01-01T00:00:00Z \
  --time-end 2024-12-31T23:59:59Z

# View local logs on VM
ssh fedora@maklab-base0-vm.tailnet-name.ts.net
cat /var/log/tailscale_install.log
cat /var/log/tailscale/install.json  # JSON format for OCI Logging
```

**Log Locations:**
- **OCI Logging**: `${var.name}-tailscale-logs` log group with 30-day retention
- **Local Logs**: `/var/log/tailscale_install.log` (human-readable)
- **JSON Logs**: `/var/log/tailscale/install.json` (structured for OCI Logging agent)
- **Cloud-Init Logs**: `/var/log/cloud-init-output.log`

### Monitor Resources
- **OCI Console**: Compute → Instances → `maklab-base0-vm`
- **Tailscale Admin**: Devices → `maklab-base0-vm`
- **Doppler Dashboard**: Secrets → `TAILSCALE_AUTH_KEY`

## ⚙️ Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `name` | Resource name | `maklab-base0` |
| `environment` | Environment name | `production` |
| `region` | OCI region | `us-phoenix-1` |
| `project_name` | Project name | `oci-arm-vm` |
| `cidr_blocks.vcn_cidr` | VCN CIDR block | `10.0.0.0/16` |
| `cidr_blocks.public_cidr` | Public subnet CIDR | `10.0.1.0/24` |
| `cidr_blocks.private_cidr` | Private subnet CIDR | `10.0.2.0/24` |
| `cidr_blocks.global_cidr` | Global CIDR | `0.0.0.0/0` |

### Hardcoded Values
- Instance shape: `VM.Standard.A1.Flex` (ARM free tier)
- vCPU: 4 (max free tier)
- RAM: 24GB (max free tier)
- Storage: 200GB block volume (max free tier)
- OS: Latest Fedora ARM image
- Ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)

## 🛠️ Maintenance

### Update Infrastructure
```bash
# Modify Terraform files
# Plan changes
make plan

# Apply changes
make apply
```

### Monitor Key Rotation
- Check GitHub Actions: `.github/workflows/tailscale-key-rotation.yml`
- Last run: GitHub → Actions → "Tailscale Key Rotation"
- Next run: Every 85 days (schedule: `0 0 */85 * *`)

### Troubleshooting

#### Tailscale Connection Issues
1. Check VM status: `oci compute instance get --instance-id <id>`
2. View cloud-init logs: Serial Console → `journalctl -u cloud-init`
3. Restart Tailscale: `sudo systemctl restart tailscale`

#### OCI API Issues
1. Verify instance principal permissions
2. Check compartment quotas
3. Validate region availability

#### Doppler Secret Issues
1. Verify Doppler token validity
2. Check project/config: `doppler configure`
3. Test secret retrieval: `doppler secrets get TAILSCALE_AUTH_KEY --plain`

## 📝 Notes

- **Free Tier Limits**: Respect OCI free tier limits (4 vCPU, 24GB RAM, 200GB storage)
- **Cost Monitoring**: Enable OCI budget alerts
- **Backup Strategy**: Consider OCI block volume backups
- **Compliance**: Log all access attempts to OCI Logging

## 🔗 References

- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci)
- [Tailscale Terraform Provider](https://registry.terraform.io/providers/tailscale/tailscale)
- [Tailscale Cloud-Init Terraform Module](https://github.com/tailscale/terraform-cloudinit-tailscale)
- [Tailscale Open-Source Terraform Module Blog Post](https://tailscale.com/blog/open-source-terraform-module)
- [Doppler Terraform Provider](https://registry.terraform.io/providers/DopplerHQ/doppler)
- [OCI Free Tier](https://www.oracle.com/cloud/free/)
- [Tailscale API](https://tailscale.com/api)
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_doppler"></a> [doppler](#requirement\_doppler) | >= 1.9.0 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 5.0.0 |
| <a name="requirement_tailscale"></a> [tailscale](#requirement\_tailscale) | >= 0.13.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_doppler"></a> [doppler](#provider\_doppler) | 1.21.1 |
| <a name="provider_oci"></a> [oci](#provider\_oci) | 8.5.0 |
| <a name="provider_tailscale"></a> [tailscale](#provider\_tailscale) | 0.28.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_logging"></a> [logging](#module\_logging) | oracle-terraform-modules/logging/oci | ~> 0.4 |
| <a name="module_vcn"></a> [vcn](#module\_vcn) | oracle-terraform-modules/vcn/oci | ~> 3.0 |
| <a name="module_vm"></a> [vm](#module\_vm) | oracle-terraform-modules/compute-instance/oci | ~> 2.4 |

## Resources

| Name | Type |
| ---- | ---- |
| [doppler_secret.tailscale_auth_key](https://registry.terraform.io/providers/DopplerHQ/doppler/latest/docs/resources/secret) | resource |
| [oci_core_security_list.public_security_list](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list) | resource |
| [tailscale_tailnet_key.vm_auth_key](https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/tailnet_key) | resource |
| [oci_core_images.oracle_linux_arm](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_images) | data source |
| [oci_core_shapes.shape_validation](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_shapes) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_DOPPLER_TOKEN"></a> [DOPPLER\_TOKEN](#input\_DOPPLER\_TOKEN) | Doppler token for accessing secrets | `string` | n/a | yes |
| <a name="input_OCI_FINGERPRINT"></a> [OCI\_FINGERPRINT](#input\_OCI\_FINGERPRINT) | OCI API key fingerprint | `string` | `""` | no |
| <a name="input_OCI_PRIVATE_KEY"></a> [OCI\_PRIVATE\_KEY](#input\_OCI\_PRIVATE\_KEY) | OCI private key for API authentication | `string` | `""` | no |
| <a name="input_OCI_TENANCY_OCID"></a> [OCI\_TENANCY\_OCID](#input\_OCI\_TENANCY\_OCID) | OCI Tenancy OCID | `string` | n/a | yes |
| <a name="input_OCI_USER_OCID"></a> [OCI\_USER\_OCID](#input\_OCI\_USER\_OCID) | OCI User OCID | `string` | `""` | no |
| <a name="input_TAILSCALE_API_KEY"></a> [TAILSCALE\_API\_KEY](#input\_TAILSCALE\_API\_KEY) | Tailscale API key for managing tailscale provider | `string` | n/a | yes |
| <a name="input_TAILSCALE_AUTH_KEY"></a> [TAILSCALE\_AUTH\_KEY](#input\_TAILSCALE\_AUTH\_KEY) | Tailscale Auth Key for creating new keys for VMs | `string` | n/a | yes |
| <a name="input_TAILSCALE_ID"></a> [TAILSCALE\_ID](#input\_TAILSCALE\_ID) | Tailscale Workspace ID | `string` | n/a | yes |
| <a name="input_alternative_regions"></a> [alternative\_regions](#input\_alternative\_regions) | List of alternative regions to try if primary region has capacity issues | `list(string)` | <pre>[<br/>  "us-phoenix-1",<br/>  "eu-frankfurt-1",<br/>  "uk-london-1"<br/>]</pre> | no |
| <a name="input_cidr_blocks"></a> [cidr\_blocks](#input\_cidr\_blocks) | CIDR blocks for networking | <pre>object({<br/>    vcn_cidr     = string<br/>    public_cidr  = string<br/>    private_cidr = string<br/>    global_cidr  = string<br/>  })</pre> | <pre>{<br/>  "global_cidr": "0.0.0.0/0",<br/>  "private_cidr": "10.0.2.0/24",<br/>  "public_cidr": "10.0.1.0/24",<br/>  "vcn_cidr": "10.0.0.0/16"<br/>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., production, staging) | `string` | `"production"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | OCI Logging retention period in days | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for resources (e.g., maklab-base0) | `string` | `"maklab-base0"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"oci-arm-vm"` | no |
| <a name="input_region"></a> [region](#input\_region) | OCI region | `string` | `"us-ashburn-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Global tags for all resources | `map(string)` | <pre>{<br/>  "environment": "development",<br/>  "managed_by": "terraform",<br/>  "project": "oci-arm-vm"<br/>}</pre> | no |
| <a name="input_tcp_protocol"></a> [tcp\_protocol](#input\_tcp\_protocol) | TCP protocol number | `string` | `"6"` | no |
| <a name="input_vm_cpu"></a> [vm\_cpu](#input\_vm\_cpu) | Number of OCPUs for flexible shapes. Reduce if experiencing capacity issues. | `number` | `2` | no |
| <a name="input_vm_memory"></a> [vm\_memory](#input\_vm\_memory) | Memory in GB for flexible shapes | `number` | `12` | no |
| <a name="input_vm_shape"></a> [vm\_shape](#input\_vm\_shape) | OCI VM shape (ARM or x86). Common options: VM.Standard.A1.Flex (ARM), VM.Standard.A2.Flex (ARM), VM.Standard.E4.Flex (x86) | `string` | `"VM.Standard.A2.Flex"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_doppler_secret_url"></a> [doppler\_secret\_url](#output\_doppler\_secret\_url) | URL to view the Tailscale auth key in Doppler |
| <a name="output_emergency_access"></a> [emergency\_access](#output\_emergency\_access) | Emergency access instructions |
| <a name="output_key_rotation_schedule"></a> [key\_rotation\_schedule](#output\_key\_rotation\_schedule) | Key rotation schedule information |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | OCI Log Group name for Tailscale logs |
| <a name="output_log_retention_days"></a> [log\_retention\_days](#output\_log\_retention\_days) | Log retention period in days |
| <a name="output_oci_logging_url"></a> [oci\_logging\_url](#output\_oci\_logging\_url) | URL to view logs in OCI Logging |
| <a name="output_shape_validation"></a> [shape\_validation](#output\_shape\_validation) | Validation that the selected VM shape is available in the region |
| <a name="output_tailscale_device_name"></a> [tailscale\_device\_name](#output\_tailscale\_device\_name) | Tailscale device name for the VM |
| <a name="output_verification_commands"></a> [verification\_commands](#output\_verification\_commands) | Commands to verify the setup |
| <a name="output_vm_instance_id"></a> [vm\_instance\_id](#output\_vm\_instance\_id) | Instance ID of the ARM VM |
| <a name="output_vm_private_ip"></a> [vm\_private\_ip](#output\_vm\_private\_ip) | Private IP address of the ARM VM |
| <a name="output_vm_public_ip"></a> [vm\_public\_ip](#output\_vm\_public\_ip) | Public IP address of the ARM VM |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

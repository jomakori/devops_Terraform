# OCI ARM VM with Tailscale Integration

Security-first ARM VM deployment on OCI Free Tier with automated Tailscale integration and 90-day key rotation.

## 📋 Features

- **Maxed-out OCI Free Tier**: 4 ARM vCPU, 24GB RAM, 200GB storage
- **Latest Fedora OS**: ARM-optimized Fedora image
- **Tailscale VPN**: Secure access with 90-day rotatable auth keys
- **Doppler Secrets**: Centralized secret management
- **Automated Key Rotation**: GitHub Actions workflow every 85 days
- **Structured Logging**: OCI Logging with JSON format
- **Security-First**: Minimal public exposure, Tailscale-only access

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
├── vm.tf               # All infrastructure resources
├── outputs.tf          # Connection details
├── cloud-init.sh       # VM initialization script
├── Makefile            # Convenience commands
└── README.md           # This file
```

## 🚀 Deployment

### Prerequisites

1. **OCI Account**: Free tier account with API credentials
2. **Tailscale Account**: API key for auth key generation
3. **Doppler Account**: Token for secret management
4. **Terraform CLI**: Version 1.5.0 or later
5. **Doppler CLI**: For secret injection

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
- **OCI Logging**: Structured JSON logs for Tailscale setup
- **Local Logs**: `/var/log/tailscale-setup.log` on VM
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
- [Doppler Terraform Provider](https://registry.terraform.io/providers/DopplerHQ/doppler)
- [OCI Free Tier](https://www.oracle.com/cloud/free/)
- [Tailscale API](https://tailscale.com/api)

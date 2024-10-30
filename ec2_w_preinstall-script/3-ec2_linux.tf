/* 
  ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ Purpose: Houses the EC2 Gateways for PowerBi & Redshift - used for Katana Reporting (Windows-based servers)      │
  └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 */

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Create/Store EC2 Keys                                                    │
  └──────────────────────────────────────────────────────────────────────────┘
 */
# Create ssh key
resource "tls_private_key" "ssh" {
  count     = length(var.gateway_environments)
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Save ref of key in AWS KMS
resource "aws_key_pair" "pubkey" {
  count      = length(var.gateway_environments)
  key_name   = "${var.gateway_name}-${var.gateway_environments[count.index]}-pubkey"
  public_key = tls_private_key.ssh[count.index].public_key_openssh
}
# Store key in Secrets Manager
resource "aws_secretsmanager_secret" "privkey" {
  # checkov:skip=CKV2_AWS_57: static key
  # checkov:skip=CKV_AWS_149: using AWS/KMS
  count = length(var.gateway_environments)
  name  = "${var.gateway_name}-${var.gateway_environments[count.index]}-privkey"

  tags = var.gateway_tags
}
# Pass/Save key to AWS Secrets Manager for reference
resource "aws_secretsmanager_secret_version" "privkey_version" {
  count         = length(var.gateway_environments)
  secret_id     = aws_secretsmanager_secret.privkey[count.index].id
  secret_string = tls_private_key.ssh[count.index].private_key_pem
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Setup EC2 Gateway Access                                                 │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "aws_security_group" "gateway_access" {
  name        = "${var.gateway_name}-gateway_access"
  description = "Whitelist access to & from ${var.gateway_name} gateways"
  vpc_id      = data.aws_vpc.gateway_vpc.id
  # Whitelist Accenture VPN users
  ingress {
    from_port       = 3389
    to_port         = 3389
    protocol        = "tcp"
    prefix_list_ids = ["pl-0eeaa81051cd80999"]
    description     = "Whitelist Accenture VPN users - USA only"
  }
  # Whitelist Splunk
  ingress {
    from_port   = 9997
    to_port     = 9997
    protocol    = "tcp"
    cidr_blocks = ["3.217.238.122/32", "54.209.134.52/32"]
    description = "Whitelist Splunk IPs"
  }
  # Whitelist encypted access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Whitelist encrypted access - via port 443"
  }
  # Enable Internet Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Enable internet access"
  }

  tags = var.gateway_tags
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Create EC2 Gateways                                                      │
  └──────────────────────────────────────────────────────────────────────────┘
 */
module "ec2-gateways" {
  # checkov:skip=CKV_AWS_88: accessible gateway
  # checkov:skip=CKV2_AWS_19: not necessary
  count  = length(var.gateway_environments) # For loop
  source = "cloudposse/ec2-instance/aws"

  name          = "${var.gateway_name}-${var.gateway_environments[count.index]}-gateway"
  ami           = "ami-0d247caf6d832766c" # Windows Server 2022 Core Base
  instance_type = "t3a.large"

  # Networking
  availability_zone           = var.gateway_az
  vpc_id                      = data.aws_vpc.gateway_vpc.id
  subnet                      = data.aws_subnet.gateway_pub_subnet.id
  security_groups             = [aws_security_group.gateway_access.id]
  security_group_enabled      = false # use existing
  associate_public_ip_address = true

  # Permit access to tools bucket
  permissions_boundary_arn = aws_iam_policy.compliance_bucket_permission.arn

  # Setup monitoring & custom tools
  user_data                   = <<-EOF
    <powershell>
    Set-SConfig -AutoLaunch $false
    $ClientID = "${var.POWERBI_CLIENT_ID}"
    $ClientSecret = "${var.POWERBI_CLIENT_SECRET}"
    $TenantID = "${var.POWERBI_TENANT_ID}"
    $recoverkey = "${var.POWERBI_RECOVER_KEY}"
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi /qn
    aws s3 cp s3://${module.compliance_bucket.s3_bucket_bucket_domain_name}/windows C:\windows_scripts --recursive
    C:\windows_scripts\install_monitoring.ps1
    C:\windows_scripts\setup_gateway.ps1
    </powershell>
    <persist>true</persist>
  EOF
  user_data_replace_on_change = true #

  # Enable ssm
  ssm_patch_manager_enabled = true

  # Use custom key
  ssh_key_pair = aws_key_pair.pubkey[count.index].key_name

  # Disk customization
  root_volume_size            = 120
  root_block_device_encrypted = true

  tags = merge(var.gateway_tags, { env = var.gateway_environments[count.index] })
}


/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Backup EC2 Gateways                                                      │
  │ Note: ACN requirement for all ec2 instances                              │
  └──────────────────────────────────────────────────────────────────────────┘
 */

module "ec2-ami-snapshot" {
  # checkov:skip=CKV_AWS_166: already encrypted - KMS
  source = "cloudposse/backup/aws"

  count            = length(var.gateway_environments) # For Loop
  name             = "${var.gateway_name}-${var.gateway_environments[count.index]}-snapshot"
  backup_resources = [module.ec2-gateways[count.index].arn]

  # Schedule
  rules = [
    {
      name              = "${var.gateway_environments[count.index]}-daily-backup"
      schedule          = "cron(00 19 * * ? *)"
      start_window      = 120
      completion_window = 360
      lifecycle = {
        delete_after = 2
      }
    }
  ]

  tags = var.gateway_tags
}

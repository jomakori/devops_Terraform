# Connection details and verification commands

output "vm_public_ip" {
  description = "Public IP address of the ARM VM"
  value       = module.vm.public_ip[0]
}

output "vm_private_ip" {
  description = "Private IP address of the ARM VM"
  value       = module.vm.private_ip[0]
}

output "vm_instance_id" {
  description = "Instance ID of the ARM VM"
  value       = module.vm.instance_id[0]
}

output "tailscale_device_name" {
  description = "Tailscale device name for the VM"
  value       = "${var.name}-vm"
}

output "doppler_secret_url" {
  description = "URL to view the Tailscale auth key in Doppler"
  value       = "https://dashboard.doppler.com/workplace/devops/projects/devops/configs/ci"
}

output "oci_logging_url" {
  description = "URL to view logs in OCI Logging"
  value       = "https://cloud.oracle.com/logging/log-groups?compartment=${var.OCI_TENANCY_OCID}"
  sensitive   = true
}

output "log_group_name" {
  description = "OCI Log Group name for Tailscale logs"
  value       = "${var.name}-tailscale-logs"
}

output "log_retention_days" {
  description = "Log retention period in days"
  value       = var.log_retention_days
}

output "verification_commands" {
  description = "Commands to verify the setup"
  value       = <<EOT
# Check Tailscale connection
tailscale status

# SSH via Tailscale
ssh fedora@${var.name}-vm.tailnet-name.ts.net

# View OCI Logging
oci logging-search search-logs --query-string "component=tailscale"

# Check VM status via OCI CLI
oci compute instance get --instance-id ${module.vm.instance_id[0]}
EOT
}

output "emergency_access" {
  description = "Emergency access instructions"
  value       = <<EOT
If Tailscale connection fails:
1. Use OCI Serial Console:
   - Navigate to OCI Console → Compute → Instances
   - Select "${var.name}-vm"
   - Click "Serial Console Connection"
   - Login with instance credentials

2. Manual Tailscale reconnect:
   sudo tailscale up --authkey=$(doppler secrets get TAILSCALE_AUTH_KEY --plain)
EOT
}

output "key_rotation_schedule" {
  description = "Key rotation schedule information"
  value       = "Tailscale auth key rotates every 90 days via GitHub Actions (runs every 85 days)"
}

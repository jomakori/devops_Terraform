output "gateway_user" {
  value       = "Administrator"
  description = "Login Username for RDP"
}

output "gateway_public_ips" {
  value       = { for idx, gateway in module.ec2-gateways : var.gateway_environments[idx] => gateway.public_ip }
  description = "Public IPs for the EC2 Gateways"
}

output "gateway_pem_keys" {
  value       = { for idx, key_arn in aws_secretsmanager_secret.privkey : var.gateway_environments[idx] => key_arn.arn }
  description = "Access PEM key via Secrets Manager - used to unveil password"
}

output "powerbi_vars" {
  value = {
    client_id     = var.POWERBI_CLIENT_ID
    client_secret = var.POWERBI_CLIENT_SECRET
    tenant_id     = var.POWERBI_TENANT_ID
    recover_key   = var.POWERBI_RECOVER_KEY
  }
  description = "PowerBI information"
}

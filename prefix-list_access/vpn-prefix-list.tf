# Whitelisted CIDR/IP blocks
locals {
  cidr_blocks = [
    # Demo VPN acess
    "192.168.10.0/24",
    "10.0.10.0/24",
    # Demo CI/CD access
    "192.168.11.0/32",
    "10.0.11.0/32",
    # Demo custom access
    "192.168.12.0/32",
    "10.0.12.0/32",
  ]
}


resource "aws_ec2_managed_prefix_list" "acn_globalprotect_ip" {
  name           = "ACN GlobalProtect VPN & CI - USA/Costa Rica"
  address_family = "IPv4"
  max_entries    = length(local.cidr_blocks)

  dynamic "entry" {
    for_each = local.cidr_blocks
    content {
      cidr        = entry.value
      description = "ACN GlobalProtect VPN & CI - USA/Costa Rica"
    }
  }
}

# For whitelisting the IP's, add this rule to the relevant SGs:
# resource "aws_security_group_rule" "allow_acn_globalprotect" {
#   description            = "ACN VPN access to <service name>"
#   type                   = "ingress"
#   from_port              = <port number>
#   to_port                = <port number>
#   protocol               = "tcp"
#   security_group_id      = <security_group_id>
#   source_prefix_list_ids = [aws_ec2_managed_prefix_list.acn_globalprotect_ip.id]
# }

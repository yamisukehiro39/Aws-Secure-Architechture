# Exposes resource identifiers so root modules can connect components safely.

# Module: transit_gateway
# Purpose: Provisions a central AWS Transit Gateway.
# File: Outputs.

output "tgw_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.this.id
}

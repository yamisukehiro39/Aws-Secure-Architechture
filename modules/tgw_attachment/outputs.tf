# Exposes resource identifiers so root modules can connect components safely.

# Module: tgw_attachment
# Purpose: Connects a VPC to a Transit Gateway with configurable appliance mode.
# File: Outputs.

output "attachment_id" {
  value = aws_ec2_transit_gateway_vpc_attachment.this.id
}

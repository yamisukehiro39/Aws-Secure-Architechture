# Module: tgw_attachment
# Purpose: Connects a VPC to a Transit Gateway with configurable appliance mode.
# File: Resources.

# Attaches VPC subnets to the TGW. The appliance-mode setting is passed by the caller.
# Automatic TGW route-table association and propagation are disabled.
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = var.tgw_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  appliance_mode_support = var.appliance_mode

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name        = var.attachment_name
    Project     = "AWS-Cloud-Security-Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

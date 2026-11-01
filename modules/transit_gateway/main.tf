# Module: transit_gateway
# Purpose: Provisions a central AWS Transit Gateway.
# File: Resources.

# Creates the central TGW with automatic association and propagation disabled;
# all attachment associations and routes are explicitly managed in root main.tf.
resource "aws_ec2_transit_gateway" "this" {
  description = "Central Transit Gateway - AWS Security Lab"

  dns_support = "enable"

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = {
    Name        = "aws-lab-central-tgw"
    Project     = "AWS-Cloud-Security-Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

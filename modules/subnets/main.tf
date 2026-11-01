# Module: subnets
# Purpose: Creates named subnets across specified Availability Zones.
# File: Resources.

# Creates one subnet per item in var.subnets. Public IP auto-assignment is disabled.
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  map_public_ip_on_launch = false

  tags = {
    Name        = each.key
    Project     = "AWS-Cloud-Security-Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }


}

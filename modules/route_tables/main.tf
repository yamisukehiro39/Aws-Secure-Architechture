# Module: route_tables
# Purpose: Creates public routing to an Internet Gateway.
# File: Resources.

# Creates the public route table.
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name        = var.route_table_name
    Project     = "AWS-Cloud-Security-Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# Adds a default IPv4 route (0.0.0.0/0) to the Internet Gateway.
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

# Associates each public subnet with the public route table.
resource "aws_route_table_association" "public" {
  for_each = var.public_subnet_ids

  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}

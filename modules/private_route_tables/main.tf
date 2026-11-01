# Module: private_route_tables
# Purpose: Creates and associates private subnet route tables.
# File: Resources.

# Creates a separate route table per private subnet.
resource "aws_route_table" "this" {
  for_each = var.private_subnet_ids

  vpc_id = var.vpc_id

  tags = {
    Name        = "${each.key}-rt"
    Project     = "AWS-Cloud-Security-Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# Links every private subnet to its corresponding route table.
resource "aws_route_table_association" "this" {
  for_each = var.private_subnet_ids

  subnet_id      = each.value
  route_table_id = aws_route_table.this[each.key].id
}

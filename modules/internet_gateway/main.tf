# Module: internet_gateway
# Purpose: Provides a VPC-level Internet Gateway attachment.
# File: Resources.

# Attaches an Internet Gateway to the specified VPC.
resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name        = var.igw_name
    Project     = "AWS-Cloud-Security-Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }

}

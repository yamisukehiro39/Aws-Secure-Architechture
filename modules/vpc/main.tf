# Module: vpc
# Purpose: Reusable Virtual Private Cloud definition.
# File: Resources.

# Creates an AWS VPC with DNS resolution and hostnames enabled.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = var.vpc_name
    Project     = "AWS-Cloud-Security-Lab"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

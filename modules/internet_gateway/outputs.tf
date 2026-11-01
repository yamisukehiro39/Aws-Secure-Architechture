# Exposes resource identifiers so root modules can connect components safely.

# Module: internet_gateway
# Purpose: Provides a VPC-level Internet Gateway attachment.
# File: Outputs.

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

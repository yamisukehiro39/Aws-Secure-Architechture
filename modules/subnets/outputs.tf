# Exposes resource identifiers so root modules can connect components safely.

# Module: subnets
# Purpose: Creates named subnets across specified Availability Zones.
# File: Outputs.

output "subnet_ids" {
  description = "IDs of the created subnets"
  value = {
    for name, subnet in aws_subnet.this :
    name => subnet.id
  }
}

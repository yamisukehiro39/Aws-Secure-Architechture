# Exposes resource identifiers so root modules can connect components safely.

# Module: private_route_tables
# Purpose: Creates and associates private subnet route tables.
# File: Outputs.

output "route_table_ids" {
  value = {
    for name, rt in aws_route_table.this :
    name => rt.id
  }
}

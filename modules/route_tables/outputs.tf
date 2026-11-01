# Exposes resource identifiers so root modules can connect components safely.

# Module: route_tables
# Purpose: Creates public routing to an Internet Gateway.
# File: Outputs.

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "public_association_ids" {
  description = "Public subnet route table associations"

  value = {
    for name, association in aws_route_table_association.public :
    name => association.id
  }
}

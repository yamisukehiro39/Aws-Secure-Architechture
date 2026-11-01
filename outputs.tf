# Root outputs expose IDs and CIDR blocks for verification and later modules.

output "application_vpc_id" {
  value = module.application_vpc.vpc_id
}

output "application_vpc_cidr" {
  value = module.application_vpc.vpc_cidr
}

output "inspection_vpc_id" {
  description = "Inspection VPC ID"
  value       = module.inspection_vpc.vpc_id
}

output "inspection_vpc_cidr" {
  description = "Inspection VPC CIDR"
  value       = module.inspection_vpc.vpc_cidr
}

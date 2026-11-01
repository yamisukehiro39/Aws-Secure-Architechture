# Inputs are supplied by the root module; do not hardcode environment secrets.

# Module: subnets
# Purpose: Creates named subnets across specified Availability Zones.
# File: Input variables.

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnets" {
  description = "Subnet configuration"
  type = map(object({
    cidr = string
    az   = string
  }))
}

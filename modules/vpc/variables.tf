# Inputs are supplied by the root module; do not hardcode environment secrets.

# Module: vpc
# Purpose: Reusable Virtual Private Cloud definition.
# File: Input variables.

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

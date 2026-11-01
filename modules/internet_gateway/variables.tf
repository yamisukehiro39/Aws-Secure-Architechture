# Inputs are supplied by the root module; do not hardcode environment secrets.

# Module: internet_gateway
# Purpose: Provides a VPC-level Internet Gateway attachment.
# File: Input variables.

variable "vpc_id" {
  description = "VPC ID for the Internet Gateway"
  type        = string
}

variable "igw_name" {
  description = "Name of the Internet Gateway"
  type        = string
}

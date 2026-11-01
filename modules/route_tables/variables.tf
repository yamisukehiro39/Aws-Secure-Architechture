# Inputs are supplied by the root module; do not hardcode environment secrets.

# Module: route_tables
# Purpose: Creates public routing to an Internet Gateway.
# File: Input variables.

variable "route_table_name" {
  description = "Name of the public route table"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the public route table"
  type        = string
}

variable "igw_id" {
  description = "ID of the Internet Gateway"
  type        = string
}

variable "public_subnet_ids" {
  description = "Map of public subnet IDs"
  type        = map(string)
}

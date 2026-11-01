# Inputs are supplied by the root module; do not hardcode environment secrets.

# Module: private_route_tables
# Purpose: Creates and associates private subnet route tables.
# File: Input variables.

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = map(string)
}

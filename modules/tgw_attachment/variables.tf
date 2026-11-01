# Inputs are supplied by the root module; do not hardcode environment secrets.

# Module: tgw_attachment
# Purpose: Connects a VPC to a Transit Gateway with configurable appliance mode.
# File: Input variables.

variable "tgw_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "appliance_mode" {
  type    = string
  default = "disable"
}

variable "attachment_name" {
  type = string
}

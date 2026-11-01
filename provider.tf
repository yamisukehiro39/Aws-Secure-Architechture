# AWS provider and execution context.
# The named local AWS CLI profile must exist on each contributor machine.
# Never commit access keys or credentials to this repository.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-3"
  profile = "terraform-admin"
}

data "aws_caller_identity" "current" {}

output "aws_identity" {
  value = data.aws_caller_identity.current.arn
}

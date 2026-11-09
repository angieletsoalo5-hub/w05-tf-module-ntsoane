# -----------------------------------------------------------------------------
# examples/basic - a root configuration that CALLS the sandbox module.
# Run all terraform commands from inside this folder.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Local backend: state is saved to terraform.tfstate in this folder.
  # Fine for a solo lab; a team would use a remote backend (see root README).
  backend "local" {}
}

# Credentials come from your local AWS CLI profile - never put keys in code.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Call the reusable module. `source` is a relative path to the module folder.
module "sandbox" {
  source = "../../modules/sandbox"

  project_name  = var.project_name
  environment   = var.environment
  instance_type = var.instance_type
  bucket_prefix = var.bucket_prefix
  owner         = var.owner
  week          = var.week
  purpose       = var.purpose
}

# Re-export the module outputs so they print after `terraform apply`.
output "instance_id" {
  description = "ID of the EC2 instance."
  value       = module.sandbox.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance."
  value       = module.sandbox.instance_public_ip
}

output "bucket_name" {
  description = "Name of the private S3 bucket."
  value       = module.sandbox.bucket_name
}

output "bucket_arn" {
  description = "ARN of the private S3 bucket."
  value       = module.sandbox.bucket_arn
}

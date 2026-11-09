# -----------------------------------------------------------------------------
# Variables for the basic example. Override them in terraform.tfvars
# (copy terraform.tfvars.example -> terraform.tfvars; the real file is git-ignored).
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Local AWS CLI profile name (keys stay in ~/.aws, never in code)."
  type        = string
  default     = "sandbox"
}

variable "project_name" {
  description = "Short name used in resource Name tags."
  type        = string
  default     = "w05-sandbox"
}

variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "lab"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name (random suffix is added)."
  type        = string
  default     = "w05-tf-module-ntsoane"
}

variable "owner" {
  description = "Owner tag."
  type        = string
  default     = "angie-ntsoane"
}

variable "week" {
  description = "Week tag."
  type        = string
  default     = "w05"
}

variable "purpose" {
  description = "Purpose tag."
  type        = string
  default     = "terraform-module-practice"
}

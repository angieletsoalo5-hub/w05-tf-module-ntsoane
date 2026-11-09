# -----------------------------------------------------------------------------
# Sandbox module
# Wraps the Week 4 stack: 1 x EC2 instance (Amazon Linux 2023) + 1 x private,
# encrypted S3 bucket with a random suffix so the name is globally unique.
#
# NOTE: a reusable module does NOT contain a `provider "aws" {}` block.
# The caller (e.g. examples/basic) configures the provider and region.
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
}

locals {
  # Tags applied to every resource. Required tags (module, environment) are
  # merged last so callers cannot accidentally override them via extra_tags.
  common_tags = merge(
    var.extra_tags,
    {
      owner       = var.owner
      week        = var.week
      purpose     = var.purpose
      project     = var.project_name
      module      = "sandbox"
      environment = var.environment
    }
  )
}

# Look up the latest Amazon Linux 2023 AMI (same filter as Week 4) so no AMI ID
# is hardcoded. Pass var.ami_id to pin a specific image instead.
data "aws_ami" "al2023" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# --- Compute -----------------------------------------------------------------

resource "aws_instance" "vm" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.al2023[0].id
  instance_type = var.instance_type

  tags = merge(local.common_tags, { Name = "${var.project_name}-vm" })
}

# --- Storage -----------------------------------------------------------------

# Random 4-byte suffix (8 hex chars) keeps the bucket name globally unique.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "private" {
  bucket        = "${var.bucket_prefix}-${random_id.suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, { Name = "${var.project_name}-bucket" })
}

# Block every form of public access to the bucket.
resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt all objects at rest with S3-managed keys (AES-256).
resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  bucket = aws_s3_bucket.private.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

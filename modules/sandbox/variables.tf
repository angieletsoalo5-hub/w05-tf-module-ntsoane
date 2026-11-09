# -----------------------------------------------------------------------------
# Inputs for the sandbox module. Every input has a safe default, so the module
# works with zero inputs, but callers can override any of them.
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Short name used in resource Name tags (e.g. \"w05-sandbox\")."
  type        = string
  default     = "w05-sandbox"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.project_name))
    error_message = "project_name must be 3-32 characters: lowercase letters, numbers and hyphens only."
  }
}

variable "environment" {
  description = "Environment tag applied to every resource."
  type        = string
  default     = "lab"

  validation {
    condition     = contains(["lab", "dev", "test"], var.environment)
    error_message = "environment must be one of: lab, dev, test."
  }
}

variable "instance_type" {
  description = "EC2 instance type. Limited to small, low-cost types for the sandbox."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small"], var.instance_type)
    error_message = "instance_type must be t2.micro, t3.micro or t3.small (keeps lab costs low)."
  }
}

variable "ami_id" {
  description = "Optional AMI ID to pin. Leave null to use the latest Amazon Linux 2023 AMI."
  type        = string
  default     = null

  validation {
    condition     = var.ami_id == null || can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "ami_id must look like \"ami-0123456789abcdef0\" or be null."
  }
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name. A random 8-character hex suffix is appended."
  type        = string
  default     = "w05-tf-module-ntsoane"

  validation {
    # S3 names are max 63 chars; prefix + "-" + 8 hex chars must fit.
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,52}[a-z0-9]$", var.bucket_prefix))
    error_message = "bucket_prefix must be 3-54 chars, lowercase letters/numbers/hyphens, and start/end with a letter or number."
  }
}

variable "force_destroy" {
  description = "If true, `terraform destroy` also deletes objects inside the bucket. Keep false unless you are sure."
  type        = bool
  default     = false
}

variable "owner" {
  description = "Owner tag (who is responsible for these resources)."
  type        = string
  default     = "angie-ntsoane"
}

variable "week" {
  description = "Week tag for the course."
  type        = string
  default     = "w05"
}

variable "purpose" {
  description = "Purpose tag."
  type        = string
  default     = "terraform-module-practice"
}

variable "extra_tags" {
  description = "Optional additional tags merged onto every resource (cannot override module/environment)."
  type        = map(string)
  default     = {}
}

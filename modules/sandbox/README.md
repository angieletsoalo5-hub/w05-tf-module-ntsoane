# Module: `sandbox`

A small, reusable Terraform module that wraps the Week 4 stack:

- **1 × EC2 instance** – latest Amazon Linux 2023 (x86_64), `t3.micro` by default
- **1 × private S3 bucket** – random suffix for a unique name, all public access blocked, AES-256 encryption at rest
- **1 × `random_id`** – generates the bucket suffix

Every resource is tagged with `module = "sandbox"` and `environment = var.environment` (default `"lab"`), plus `owner`, `week`, `purpose` and `project`.

> The module has **no `provider` block**. The calling configuration sets the AWS provider (region, profile).

## Usage

```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "sandbox"
}

module "sandbox" {
  source = "../../modules/sandbox"

  project_name  = "w05-sandbox"
  environment   = "lab"
  instance_type = "t3.micro"
  bucket_prefix = "w05-tf-module-ntsoane"
}

output "bucket_name" {
  value = module.sandbox.bucket_name
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.0 |
| hashicorp/aws | ~> 5.0 |
| hashicorp/random | ~> 3.6 |

## Resources

| Type | Name |
|---|---|
| data source | `aws_ami.al2023` (skipped if `ami_id` is set) |
| resource | `aws_instance.vm` |
| resource | `random_id.suffix` |
| resource | `aws_s3_bucket.private` |
| resource | `aws_s3_bucket_public_access_block.private` |
| resource | `aws_s3_bucket_server_side_encryption_configuration.private` |

## Inputs

| Name | Description | Type | Default | Validation |
|---|---|---|---|---|
| `project_name` | Short name used in `Name` tags | `string` | `"w05-sandbox"` | 3–32 chars, `a-z0-9-` |
| `environment` | Environment tag | `string` | `"lab"` | `lab`, `dev` or `test` |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` | `t2.micro`, `t3.micro`, `t3.small` |
| `ami_id` | Pin a specific AMI (null = latest AL2023) | `string` | `null` | `ami-` + 8–17 hex chars |
| `bucket_prefix` | Bucket name prefix (8-char hex suffix added) | `string` | `"w05-tf-module-ntsoane"` | 3–54 chars, valid S3 characters |
| `force_destroy` | Delete bucket objects on destroy | `bool` | `false` | – |
| `owner` | Owner tag | `string` | `"angie-ntsoane"` | – |
| `week` | Week tag | `string` | `"w05"` | – |
| `purpose` | Purpose tag | `string` | `"terraform-module-practice"` | – |
| `extra_tags` | Extra tags (cannot override `module`/`environment`) | `map(string)` | `{}` | – |

## Outputs

| Name | Description |
|---|---|
| `instance_id` | ID of the EC2 instance |
| `instance_public_ip` | Public IP of the EC2 instance |
| `instance_ami` | AMI ID the instance was launched from |
| `bucket_name` | Name of the private S3 bucket |
| `bucket_arn` | ARN of the private S3 bucket |
| `tags` | Common tags applied to all resources |

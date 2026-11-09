# -----------------------------------------------------------------------------
# Outputs: values the caller can read after `terraform apply`.
# -----------------------------------------------------------------------------

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.vm.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance (empty if the subnet does not assign one)."
  value       = aws_instance.vm.public_ip
}

output "instance_ami" {
  description = "AMI ID the instance was launched from."
  value       = aws_instance.vm.ami
}

output "bucket_name" {
  description = "Name of the private S3 bucket."
  value       = aws_s3_bucket.private.bucket
}

output "bucket_arn" {
  description = "ARN of the private S3 bucket."
  value       = aws_s3_bucket.private.arn
}

output "tags" {
  description = "Common tags applied to all resources."
  value       = local.common_tags
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.this.public_dns
}

output "security_group_id" {
  description = "Security group ID attached to the instance"
  value       = aws_security_group.ec2.id
}

output "iam_role_name" {
  description = "IAM role name attached to the instance"
  value       = aws_iam_role.ec2.name
}

output "cloudwatch_log_group_app" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.app.name
}

output "cloudwatch_log_group_system" {
  description = "CloudWatch log group for system logs"
  value       = aws_cloudwatch_log_group.system.name
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.web.public_dns
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "iam_role_name" {
  description = "IAM role name attached to the instance"
  value       = aws_iam_role.ec2.name
}

output "system_log_group_name" {
  description = "CloudWatch log group for system logs"
  value       = aws_cloudwatch_log_group.system.name
}

output "app_log_group_name" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.app.name
}

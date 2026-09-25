output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public (load-balancer tier) subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private (application tier) subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database tier subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Elastic IPs of the NAT gateways"
  value       = module.vpc.nat_gateway_public_ips
}

output "db_subnet_group_name" {
  description = "RDS DB Subnet Group name"
  value       = module.vpc.db_subnet_group_name
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

# ── EC2 ──────────────────────────────────────────────────────────────────────

output "ec2_instance_id" {
  description = "Web server EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Web server public IP"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Web server public DNS"
  value       = module.ec2.public_dns
}

output "ec2_security_group_id" {
  description = "Security group ID attached to the web server"
  value       = module.ec2.security_group_id
}

output "ec2_log_group_app" {
  description = "CloudWatch log group for application logs"
  value       = module.ec2.cloudwatch_log_group_app
}

output "ec2_log_group_system" {
  description = "CloudWatch log group for system logs"
  value       = module.ec2.cloudwatch_log_group_system
}

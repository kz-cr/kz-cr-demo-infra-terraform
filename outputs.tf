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

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "EC2 public DNS"
  value       = module.ec2.public_dns
}

output "ec2_system_log_group" {
  description = "CloudWatch log group for system logs"
  value       = module.ec2.system_log_group_name
}

output "ec2_app_log_group" {
  description = "CloudWatch log group for app logs"
  value       = module.ec2.app_log_group_name
}

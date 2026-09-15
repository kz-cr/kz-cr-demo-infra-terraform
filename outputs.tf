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

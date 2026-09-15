output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

# Tier 1 — public
output "public_subnet_ids" {
  description = "Public subnet IDs (load-balancer tier)"
  value       = aws_subnet.public[*].id
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

# Tier 2 — private / application
output "private_subnet_ids" {
  description = "Private subnet IDs (application tier)"
  value       = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  description = "Private route table IDs (one per NAT gateway)"
  value       = aws_route_table.private[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs allocated to the NAT gateways"
  value       = aws_eip.nat[*].public_ip
}

# Tier 3 — database
output "database_subnet_ids" {
  description = "Database subnet IDs (data tier, no internet)"
  value       = aws_subnet.database[*].id
}

output "database_route_table_id" {
  description = "Database route table ID"
  value       = aws_route_table.database.id
}

output "db_subnet_group_name" {
  description = "RDS DB Subnet Group name"
  value       = aws_db_subnet_group.this.name
}

output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.this.id
}

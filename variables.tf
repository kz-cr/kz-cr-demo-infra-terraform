variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "kz-cr-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones (must match the number of subnet CIDRs)"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "public_subnets" {
  description = "CIDR blocks for the public (load-balancer) tier — one per AZ"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for the private (application) tier — one per AZ"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnets" {
  description = "CIDR blocks for the database tier (no internet access) — one per AZ"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets (reduces cost; avoid in production)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags merged onto every resource"
  type        = map(string)
  default     = {}
}

variable "ec2_instance_type" {
  description = "EC2 instance type for the web server"
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  description = "AMI ID — leave empty to auto-resolve latest Amazon Linux 2023"
  type        = string
  default     = ""
}

variable "ec2_key_name" {
  description = "EC2 key pair name for SSH access — leave empty to disable"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 30
}

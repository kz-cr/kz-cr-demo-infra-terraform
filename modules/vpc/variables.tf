variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "azs" {
  description = "List of availability zones — must have the same length as each subnet list"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 1
    error_message = "At least one availability zone is required."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private/application subnets (one per AZ)"
  type        = list(string)
}

variable "database_subnets" {
  description = "CIDR blocks for database subnets (one per AZ, no internet access)"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Create one NAT gateway shared by all AZs instead of one per AZ"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags merged onto every resource"
  type        = map(string)
  default     = {}
}

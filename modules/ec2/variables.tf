variable "name" {
  description = "Name prefix applied to all resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC to place the instance and security group in"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance into (should be a public subnet)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID — leave empty to auto-resolve the latest Amazon Linux 2023 x86_64 image"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "EC2 key pair name for SSH access — leave empty to disable"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket from which to download binaries and dependencies on first boot"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket — used to grant the instance IAM read access"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Extra tags merged onto every resource"
  type        = map(string)
  default     = {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project   = var.name
        ManagedBy = "terraform"
      },
      var.tags
    )
  }
}

module "vpc" {
  source = "./modules/vpc"

  name             = var.name
  vpc_cidr         = var.vpc_cidr
  azs              = var.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  single_nat_gateway = var.single_nat_gateway

  tags = var.tags
}

module "ec2" {
  source = "./modules/ec2"

  name      = "${var.name}-web"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]

  instance_type      = var.ec2_instance_type
  ami_id             = var.ec2_ami_id
  key_name           = var.ec2_key_name
  log_retention_days = var.log_retention_days

  tags = var.tags
}

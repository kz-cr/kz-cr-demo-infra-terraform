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

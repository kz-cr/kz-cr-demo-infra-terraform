# Unit tests for the 3-tier VPC module.
# Uses mock_provider so no real AWS credentials are required.
# Run with: terraform test -filter=tests/vpc_unit.tftest.hcl

mock_provider "aws" {}

# ── Shared variable block reused across runs ─────────────────────────────────

variables {
  name             = "test"
  vpc_cidr         = "10.0.0.0/16"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
  single_nat_gateway = false
}

# ── VPC configuration ────────────────────────────────────────────────────────

run "vpc_cidr_matches_input" {
  command = plan

  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block must match the input variable."
  }
}

# ── Subnet counts ─────────────────────────────────────────────────────────────

run "three_subnets_per_tier" {
  command = plan

  assert {
    condition     = length(module.vpc.public_subnet_ids) == 3
    error_message = "Expected 3 public subnets (one per AZ)."
  }

  assert {
    condition     = length(module.vpc.private_subnet_ids) == 3
    error_message = "Expected 3 private subnets (one per AZ)."
  }

  assert {
    condition     = length(module.vpc.database_subnet_ids) == 3
    error_message = "Expected 3 database subnets (one per AZ)."
  }
}

# ── NAT Gateway: multi-AZ mode ───────────────────────────────────────────────

run "multi_az_nat_creates_one_per_az" {
  command = plan

  variables {
    single_nat_gateway = false
  }

  assert {
    condition     = length(module.vpc.nat_gateway_ids) == 3
    error_message = "Expected one NAT gateway per AZ when single_nat_gateway=false."
  }

  assert {
    condition     = length(module.vpc.private_route_table_ids) == 3
    error_message = "Expected one private route table per NAT gateway."
  }
}

# ── NAT Gateway: single mode (cost-saving) ───────────────────────────────────

run "single_nat_gateway_flag_reduces_nat_count" {
  command = plan

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(module.vpc.nat_gateway_ids) == 1
    error_message = "Expected exactly one NAT gateway when single_nat_gateway=true."
  }

  assert {
    condition     = length(module.vpc.private_route_table_ids) == 1
    error_message = "Expected one shared private route table when single_nat_gateway=true."
  }
}

# ── Two-AZ deployment ─────────────────────────────────────────────────────────

run "two_az_deployment" {
  command = plan

  variables {
    azs              = ["us-east-1a", "us-east-1b"]
    public_subnets   = ["10.0.0.0/24", "10.0.1.0/24"]
    private_subnets  = ["10.0.10.0/24", "10.0.11.0/24"]
    database_subnets = ["10.0.20.0/24", "10.0.21.0/24"]
    single_nat_gateway = false
  }

  assert {
    condition     = length(module.vpc.public_subnet_ids) == 2
    error_message = "Expected 2 public subnets for a two-AZ deployment."
  }

  assert {
    condition     = length(module.vpc.nat_gateway_ids) == 2
    error_message = "Expected 2 NAT gateways for a two-AZ deployment."
  }
}

# ── Database tier CIDR is in the expected range ───────────────────────────────
# Plan-time check: all DB subnet CIDRs must fall within the VPC CIDR.

run "database_subnets_within_vpc_cidr" {
  command = plan

  assert {
    condition = alltrue([
      for cidr in var.database_subnets :
      startswith(cidr, "10.0.20.") || startswith(cidr, "10.0.21.") || startswith(cidr, "10.0.22.")
    ])
    error_message = "Database subnet CIDRs must use the expected 10.0.20-22.x ranges."
  }
}

# ── DB subnet group name follows naming convention ────────────────────────────

run "db_subnet_group_name_convention" {
  command = plan

  assert {
    condition     = module.vpc.db_subnet_group_name == "${var.name}-db-subnet-group"
    error_message = "DB subnet group must be named <name>-db-subnet-group."
  }
}

# Integration tests — creates real AWS resources then destroys them.
# Requires valid AWS credentials and will incur costs (EIPs, NAT gateways).
# Run with: terraform test -filter=tests/vpc_integration.tftest.hcl
#
# Estimated test duration: ~5 min (NAT gateway provisioning is the bottleneck).

provider "aws" {
  region = "us-east-1"
}

variables {
  name               = "tftest-vpc"
  vpc_cidr           = "10.99.0.0/16"
  azs                = ["us-east-1a", "us-east-1b"]
  public_subnets     = ["10.99.0.0/24", "10.99.1.0/24"]
  private_subnets    = ["10.99.10.0/24", "10.99.11.0/24"]
  database_subnets   = ["10.99.20.0/24", "10.99.21.0/24"]
  single_nat_gateway = true # minimise cost during tests
  tags               = { Environment = "test" }
}

# ── Apply: verify real resource attributes ───────────────────────────────────

run "vpc_is_created" {
  command = apply

  assert {
    condition     = module.vpc.vpc_cidr_block == "10.99.0.0/16"
    error_message = "VPC CIDR must match the requested block."
  }
}

run "subnets_span_correct_azs" {
  command = apply

  assert {
    condition     = length(module.vpc.public_subnet_ids) == 2
    error_message = "Expected 2 public subnets."
  }

  assert {
    condition     = length(module.vpc.private_subnet_ids) == 2
    error_message = "Expected 2 private subnets."
  }

  assert {
    condition     = length(module.vpc.database_subnet_ids) == 2
    error_message = "Expected 2 database subnets."
  }
}

run "single_nat_gateway_in_effect" {
  command = apply

  assert {
    condition     = length(module.vpc.nat_gateway_ids) == 1
    error_message = "Expected exactly 1 NAT gateway with single_nat_gateway=true."
  }

  assert {
    condition     = length(module.vpc.nat_gateway_public_ips) == 1
    error_message = "Expected 1 Elastic IP for the NAT gateway."
  }
}

run "db_subnet_group_exists" {
  command = apply

  assert {
    condition     = module.vpc.db_subnet_group_name == "tftest-vpc-db-subnet-group"
    error_message = "DB subnet group name does not match the expected convention."
  }
}

run "flow_log_is_active" {
  command = apply

  assert {
    condition     = module.vpc.flow_log_id != null && module.vpc.flow_log_id != ""
    error_message = "VPC flow log must be created."
  }
}

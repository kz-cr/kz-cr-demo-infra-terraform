# kz-cr-demo-infra-terraform

Terraform configuration for a 3-tier AWS VPC with a public-facing EC2 web server, built as reusable modules with native Terraform test coverage and GitHub Actions CI.

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────┐
│  VPC (10.0.0.0/16)                              │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Tier 1 — Public  (10.0.0-2.0/24)      │   │
│  │  EC2 web server (HTTP/HTTPS)            │   │
│  │  Route: → Internet Gateway              │   │
│  └──────────────────┬──────────────────────┘   │
│                     │ NAT Gateway               │
│  ┌──────────────────▼──────────────────────┐   │
│  │  Tier 2 — Private  (10.0.10-12.0/24)   │   │
│  │  Application servers, ECS tasks         │   │
│  │  Route: → NAT Gateway                   │   │
│  └──────────────────┬──────────────────────┘   │
│                     │ (no route out)            │
│  ┌──────────────────▼──────────────────────┐   │
│  │  Tier 3 — Database  (10.0.20-22.0/24)  │   │
│  │  RDS, ElastiCache                       │   │
│  │  Route: none (fully isolated)           │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

All three tiers span 3 Availability Zones by default. The database tier has no internet route and is only reachable from within the VPC.

## Repository layout

```
.
├── main.tf                        # Provider + root module calls
├── variables.tf                   # Input variables
├── outputs.tf                     # Root outputs
├── versions.tf                    # Terraform & provider version pins
├── terraform.tfvars.example       # Example values — copy to terraform.tfvars
├── modules/
│   ├── vpc/
│   │   ├── main.tf                # All VPC resources
│   │   ├── variables.tf           # Module inputs (with validation)
│   │   └── outputs.tf             # Module outputs
│   └── ec2/
│       ├── main.tf                # EC2 instance, SG, IAM role, CloudWatch logs
│       ├── variables.tf           # Module inputs
│       └── outputs.tf             # Module outputs
└── tests/
    ├── vpc_unit.tftest.hcl        # Mock-provider unit tests (no AWS needed)
    └── vpc_integration.tftest.hcl # Apply-based integration tests (real AWS)
```

## Prerequisites

| Tool | Version |
|------|---------|
| Terraform | >= 1.7.0 |
| AWS CLI | >= 2.x |
| AWS credentials | Required for `plan`/`apply` and integration tests |

## Usage

```bash
# 1. Copy and edit the example variables
cp terraform.tfvars.example terraform.tfvars

# 2. Initialise
terraform init

# 3. Preview changes
terraform plan

# 4. Apply
terraform apply
```

### Key variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `ap-southeast-1` | AWS region |
| `name` | `kz-cr-demo` | Name prefix for all resources |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `azs` | 3 AZs in ap-southeast-1 | Availability zones |
| `single_nat_gateway` | `false` | `true` = one shared NAT GW (saves cost in non-prod) |
| `ec2_instance_type` | `t3.micro` | Instance type for the web server |
| `ec2_ami_id` | `""` | AMI ID — leave empty to use latest Amazon Linux 2023 |
| `ec2_key_name` | `""` | EC2 key pair for SSH — leave empty to disable SSH |
| `log_retention_days` | `30` | CloudWatch log retention for EC2 log groups |

## Tests

### Unit tests — no AWS credentials required

Uses Terraform's `mock_provider` (requires Terraform >= 1.7). Runs in CI on every push and PR.

```bash
terraform test -filter=tests/vpc_unit.tftest.hcl -verbose
```

**Test cases:**
- VPC CIDR matches input
- 3 subnets created per tier
- Multi-AZ mode creates one NAT gateway per AZ
- `single_nat_gateway=true` reduces NAT count to 1
- Two-AZ deployment scales correctly
- Database subnet CIDRs are in the expected ranges
- DB subnet group follows naming convention

### Integration tests — real AWS resources

Creates actual resources in AWS, asserts on their attributes, then destroys them automatically. Takes ~5 minutes (NAT gateway provisioning).

```bash
terraform test -filter=tests/vpc_integration.tftest.hcl -verbose
```

## CI/CD

GitHub Actions runs two jobs on every push/PR to `main`:

| Job | Trigger | AWS needed |
|-----|---------|------------|
| `Validate & Unit Tests` | Every push / PR | No |
| `Integration Tests` | Push to `main` or `run-integration` PR label | Yes (OIDC) |

### Setting up integration tests in CI

1. Create an IAM role with an OIDC trust policy for `token.actions.githubusercontent.com` scoped to this repository.
2. Add the role ARN as a GitHub Actions secret named `AWS_ROLE_ARN`.
3. Create a GitHub environment named `integration` (Settings → Environments) — add optional manual approval if desired.

## What gets created

### VPC module

| Resource | Count | Notes |
|----------|-------|-------|
| VPC | 1 | DNS hostnames + support enabled |
| Internet Gateway | 1 | Attached to public subnets |
| Public subnets | 1 per AZ | `map_public_ip_on_launch = true` |
| Private subnets | 1 per AZ | Application tier |
| Database subnets | 1 per AZ | No internet route |
| NAT Gateways | 1 or 1 per AZ | Controlled by `single_nat_gateway` |
| Elastic IPs | 1 per NAT GW | |
| Route tables | public + private + database | |
| RDS DB Subnet Group | 1 | Spans all database subnets |
| VPC Flow Logs | 1 | 30-day CloudWatch retention |

### EC2 module

| Resource | Count | Notes |
|----------|-------|-------|
| EC2 instance | 1 | Amazon Linux 2023, public subnet, public IP assigned |
| Security group | 1 | Ingress 80 + 443 from `0.0.0.0/0`; unrestricted egress |
| IAM role + instance profile | 1 | `CloudWatchAgentServerPolicy` attached |
| CloudWatch log group `/ec2/<name>/system` | 1 | `/var/log/messages` + cloud-init output |
| CloudWatch log group `/ec2/<name>/app` | 1 | `/var/log/app/*.log` |
| EBS root volume | 1 | 20 GB gp3, encrypted |

The CloudWatch Agent is installed and started via `user_data` on first boot. IMDSv2 is enforced (`http_tokens = required`).

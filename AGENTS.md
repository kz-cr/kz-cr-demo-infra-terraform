# kz-cr-demo-infra-terraform

Terraform configuration for a 3-tier AWS VPC with a public-facing EC2 web server. Root module calls two local child modules: `modules/vpc` and `modules/ec2`. No remote state backend is configured — `terraform init -backend=false` is the norm here.

## Stack

- Terraform >= 1.7.0 (uses `mock_provider` in tests)
- AWS provider ~> 5.0
- Default region: `ap-southeast-1` (Singapore); 3 AZs: `ap-southeast-1a/b/c`

## Layout

```
main.tf                   # Provider config + module calls (vpc + ec2)
variables.tf              # Root inputs
outputs.tf                # Root outputs (vpc_id, subnet IDs, NAT EIPs, EC2 IP/DNS, log groups)
versions.tf               # Version pins
terraform.tfvars.example  # Copy → terraform.tfvars before applying
modules/vpc/
  main.tf                 # All VPC resources (subnets, route tables, NAT GWs, flow logs)
  variables.tf            # Module inputs with validation
  outputs.tf              # Module outputs
modules/ec2/
  main.tf                 # EC2 instance, security group, IAM role, CloudWatch log groups + agent
  variables.tf            # Module inputs
  outputs.tf              # Module outputs (instance_id, public_ip, public_dns, SG ID, log group names)
tests/
  vpc_unit.tftest.hcl        # Mock-provider unit tests (no AWS needed)
  vpc_integration.tftest.hcl # Apply-based integration tests (real AWS, ~5 min)
.github/workflows/terraform-test.yml  # CI: validate + unit on every PR, integration on push to main
```

## Common commands

```bash
# First-time setup
cp terraform.tfvars.example terraform.tfvars
terraform init

terraform fmt -recursive        # Format (CI enforces this)
terraform validate
terraform plan
terraform apply

# Unit tests — no credentials required
terraform test -filter=tests/vpc_unit.tftest.hcl -verbose

# Integration tests — requires AWS credentials
terraform test -filter=tests/vpc_integration.tftest.hcl -verbose
```

## Key design decisions

**VPC module**
- **NAT gateway count** is controlled by `single_nat_gateway`: `false` (default) = one per AZ for HA; `true` = one shared NAT to save cost in non-prod.
- **Database tier has no internet route** — `aws_route_table.database` is intentionally empty. Never add a default route to it.
- **All subnet lists must have the same length as `azs`** — the module uses `count.index` to pair AZs with CIDRs. Mismatched lengths cause an index error.
- **Default tags** (`Project`, `ManagedBy=terraform`) are injected via `provider.default_tags`; the `tags` variable merges additional tags on top.
- **Flow logs** ship to CloudWatch with 30-day retention. The IAM role is created inline in the vpc module.

**EC2 module**
- **Placed in the first public subnet** (`module.vpc.public_subnet_ids[0]`). To spread across AZs, the caller would need to loop over subnets.
- **Security group** allows inbound 80 and 443 from `0.0.0.0/0` and `::/0`. No SSH ingress by default — set `ec2_key_name` to enable key-pair access, then add port 22 to the SG separately if needed.
- **CloudWatch Agent** is installed via `user_data` on first boot. It ships `/var/log/messages`, `cloud-init-output.log`, and `/var/log/app/*.log` to two log groups (`/ec2/<name>/system` and `/ec2/<name>/app`). App logs are expected at `/var/log/app/*.log`.
- **IMDSv2 enforced** (`http_tokens = required`) to mitigate SSRF-based metadata exfiltration.
- **AMI** auto-resolves to the latest Amazon Linux 2023 x86_64 image via a data source when `ec2_ami_id` is left empty.

## CI

Two jobs in `.github/workflows/terraform-test.yml`:
- **Validate & Unit Tests** — runs on every push/PR, no AWS credentials needed.
- **Integration Tests** — runs on push to `main` or when the PR label `run-integration` is applied. Requires `AWS_ROLE_ARN` secret and a `integration` GitHub environment. Uses OIDC — no long-lived keys.

## Variables to know

| Variable | Default | Notes |
|---|---|---|
| `region` | `ap-southeast-1` | AWS region |
| `azs` | `[ap-southeast-1a/b/c]` | Must match subnet list lengths |
| `single_nat_gateway` | `false` | Set `true` in non-prod to cut NAT costs |
| `name` | `kz-cr-demo` | Prefix applied to every resource name |
| `vpc_cidr` | `10.0.0.0/16` | Must be a valid CIDR (validated in module) |
| `ec2_instance_type` | `t3.micro` | Web server instance type |
| `ec2_ami_id` | `""` | Leave empty to auto-resolve latest AL2023 |
| `ec2_key_name` | `""` | Leave empty to disable SSH key pair |
| `log_retention_days` | `30` | Retention for EC2 CloudWatch log groups |

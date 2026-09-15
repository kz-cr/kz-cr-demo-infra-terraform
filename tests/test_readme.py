"""Contract tests for the repository documentation added by PR #1."""

from __future__ import annotations

import ast
import ipaddress
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
README = (ROOT / "README.md").read_text(encoding="utf-8")


def markdown_section(title: str) -> str:
    """Return a Markdown section, stopping at the next peer heading."""
    match = re.search(
        rf"^(?P<marks>#+) {re.escape(title)}\s*$",
        README,
        flags=re.MULTILINE,
    )
    if match is None:
        raise AssertionError(f"README section not found: {title}")

    level = len(match.group("marks"))
    next_heading = re.search(
        rf"^#{{{level}}} ",
        README[match.end() :],
        flags=re.MULTILINE,
    )
    end = match.end() + next_heading.start() if next_heading else len(README)
    return README[match.end() : end]


def markdown_table(section: str) -> list[dict[str, str]]:
    """Parse the first pipe-delimited table in a Markdown section."""
    rows = [
        [cell.strip() for cell in line.strip().strip("|").split("|")]
        for line in section.splitlines()
        if line.strip().startswith("|")
    ]
    if len(rows) < 2:
        raise AssertionError("Markdown table not found")

    headers = rows[0]
    return [dict(zip(headers, row)) for row in rows[2:]]


def hcl_named_block(source: str, kind: str, *labels: str) -> str:
    """Extract a named top-level HCL block using balanced braces."""
    quoted_labels = r"\s+".join(rf'"{re.escape(label)}"' for label in labels)
    start = re.search(rf"\b{re.escape(kind)}\s+{quoted_labels}\s*\{{", source)
    if start is None:
        raise AssertionError(f"HCL block not found: {kind} {labels}")

    depth = 0
    for index in range(start.end() - 1, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[start.start() : index + 1]
    raise AssertionError(f"Unclosed HCL block: {kind} {labels}")


def root_variable_defaults() -> dict[str, object]:
    source = (ROOT / "variables.tf").read_text(encoding="utf-8")
    defaults: dict[str, object] = {}
    for name in re.findall(r'^variable\s+"([^"]+)"\s*\{', source, re.MULTILINE):
        block = hcl_named_block(source, "variable", name)
        match = re.search(r"^\s*default\s*=\s*(.+)$", block, re.MULTILINE)
        if match is None:
            continue
        value = re.sub(r"\btrue\b", "True", match.group(1))
        value = re.sub(r"\bfalse\b", "False", value)
        defaults[name] = ast.literal_eval(value)
    return defaults


def documented_layout_paths() -> set[str]:
    section = markdown_section("Repository layout")
    tree = re.search(r"```\n(?P<body>.*?)\n```", section, re.DOTALL)
    if tree is None:
        raise AssertionError("Repository layout tree not found")

    directories: dict[int, str] = {}
    paths: set[str] = set()
    for line in tree.group("body").splitlines():
        item = re.match(r"(?P<prefix>(?:│   |    )*)(?:├──|└──) (?P<name>\S+)", line)
        if item is None:
            continue
        depth = len(item.group("prefix")) // 4
        name = item.group("name")
        parents = [directories[index] for index in range(depth)]
        path = "/".join([*parents, name.rstrip("/")])
        paths.add(path)
        if name.endswith("/"):
            directories[depth] = name.rstrip("/")
            directories = {key: value for key, value in directories.items() if key <= depth}
    return paths


def compact_subnet_range(cidrs: list[str]) -> str:
    networks = [ipaddress.ip_network(cidr) for cidr in cidrs]
    first, last = networks[0], networks[-1]
    first_parts = str(first.network_address).split(".")
    last_parts = str(last.network_address).split(".")
    if first_parts[:2] != last_parts[:2] or first.prefixlen != last.prefixlen:
        raise AssertionError("README diagram only supports compact ranges within a /16")
    return f"{'.'.join(first_parts[:2])}.{first_parts[2]}-{last_parts[2]}.0/{first.prefixlen}"


class ReadmeContractTests(unittest.TestCase):
    def test_repository_layout_references_existing_paths(self) -> None:
        documented_paths = documented_layout_paths()
        self.assertGreaterEqual(len(documented_paths), 12)
        for relative_path in documented_paths:
            with self.subTest(path=relative_path):
                self.assertTrue((ROOT / relative_path).exists())

    def test_key_variable_defaults_match_root_configuration(self) -> None:
        rows = markdown_table(markdown_section("Key variables"))
        documented = {row["Variable"].strip("`"): row["Default"].strip("`") for row in rows}
        defaults = root_variable_defaults()

        self.assertEqual(documented["region"], defaults["region"])
        self.assertEqual(documented["name"], defaults["name"])
        self.assertEqual(documented["vpc_cidr"], defaults["vpc_cidr"])
        self.assertEqual(documented["single_nat_gateway"], str(defaults["single_nat_gateway"]).lower())

        azs = defaults["azs"]
        self.assertEqual(documented["azs"], "3 AZs in us-east-1")
        self.assertEqual(len(azs), 3)
        self.assertTrue(all(str(az).startswith("us-east-1") for az in azs))

    def test_terraform_prerequisite_matches_required_version(self) -> None:
        prerequisite_rows = markdown_table(markdown_section("Prerequisites"))
        terraform_row = next(row for row in prerequisite_rows if row["Tool"] == "Terraform")
        versions = (ROOT / "versions.tf").read_text(encoding="utf-8")
        required = re.search(r'required_version\s*=\s*"([^"]+)"', versions)

        self.assertIsNotNone(required)
        self.assertEqual(terraform_row["Version"], required.group(1))
        self.assertIn("mock_provider", (ROOT / "tests/vpc_unit.tftest.hcl").read_text())

    def test_usage_commands_are_complete_and_ordered(self) -> None:
        usage = markdown_section("Usage")
        bash_block = re.search(r"```bash\n(?P<body>.*?)\n```", usage, re.DOTALL)
        self.assertIsNotNone(bash_block)
        commands = [
            line
            for line in bash_block.group("body").splitlines()
            if line and not line.startswith("#")
        ]
        self.assertEqual(
            commands,
            [
                "cp terraform.tfvars.example terraform.tfvars",
                "terraform init",
                "terraform plan",
                "terraform apply",
            ],
        )
        self.assertTrue((ROOT / "terraform.tfvars.example").is_file())

    def test_documented_test_commands_target_the_test_suites(self) -> None:
        commands = re.findall(r"terraform test -filter=([^\s]+) -verbose", README)
        self.assertEqual(
            commands,
            ["tests/vpc_unit.tftest.hcl", "tests/vpc_integration.tftest.hcl"],
        )
        for relative_path in commands:
            with self.subTest(path=relative_path):
                self.assertTrue((ROOT / relative_path).is_file())

    def test_documented_unit_cases_have_matching_terraform_runs(self) -> None:
        unit_section = markdown_section("Unit tests — no AWS credentials required")
        documented_cases = {
            line.removeprefix("- ")
            for line in unit_section.splitlines()
            if line.startswith("- ")
        }
        expected_cases = {
            "VPC CIDR matches input": "vpc_cidr_matches_input",
            "3 subnets created per tier": "three_subnets_per_tier",
            "Multi-AZ mode creates one NAT gateway per AZ": "multi_az_nat_creates_one_per_az",
            "`single_nat_gateway=true` reduces NAT count to 1": "single_nat_gateway_flag_reduces_nat_count",
            "Two-AZ deployment scales correctly": "two_az_deployment",
            "Database subnet CIDRs are in the expected ranges": "database_subnets_within_vpc_cidr",
            "DB subnet group follows naming convention": "db_subnet_group_name_convention",
        }
        test_source = (ROOT / "tests/vpc_unit.tftest.hcl").read_text(encoding="utf-8")
        actual_runs = set(re.findall(r'^run\s+"([^"]+)"', test_source, re.MULTILINE))

        self.assertEqual(documented_cases, set(expected_cases))
        self.assertEqual(actual_runs, set(expected_cases.values()))

    def test_architecture_diagram_matches_default_network_topology(self) -> None:
        defaults = root_variable_defaults()
        architecture = markdown_section("Architecture")

        self.assertIn(f"VPC ({defaults['vpc_cidr']})", architecture)
        for tier in ("public", "private", "database"):
            with self.subTest(tier=tier):
                cidrs = defaults[f"{tier}_subnets"]
                self.assertEqual(len(cidrs), len(defaults["azs"]))
                self.assertIn(f"({compact_subnet_range(cidrs)})", architecture)
        self.assertIn("All three tiers span 3 Availability Zones by default", architecture)

    def test_database_isolation_claim_matches_route_table_configuration(self) -> None:
        module = (ROOT / "modules/vpc/main.tf").read_text(encoding="utf-8")
        public_routes = hcl_named_block(module, "resource", "aws_route_table", "public")
        private_routes = hcl_named_block(module, "resource", "aws_route_table", "private")
        database_routes = hcl_named_block(module, "resource", "aws_route_table", "database")
        architecture = markdown_section("Architecture")

        self.assertIn('cidr_block = "0.0.0.0/0"', public_routes)
        self.assertIn('cidr_block     = "0.0.0.0/0"', private_routes)
        self.assertNotIn("route {", database_routes)
        self.assertIn("Route: none (fully isolated)", architecture)

    def test_ci_jobs_and_integration_gate_match_workflow(self) -> None:
        rows = markdown_table(markdown_section("CI/CD"))
        workflow = (ROOT / ".github/workflows/terraform-test.yml").read_text(encoding="utf-8")

        for row in rows:
            with self.subTest(job=row["Job"]):
                job_name = row["Job"].strip("`")
                self.assertRegex(workflow, rf"(?m)^\s+name: {re.escape(job_name)}$")
        self.assertRegex(workflow, r"(?m)^\s+branches: \[main\]$")
        self.assertIn("github.event_name == 'push'", workflow)
        self.assertIn("'run-integration'", workflow)
        self.assertIn("Push to `main` or `run-integration` PR label", rows[1]["Trigger"])

    def test_resource_inventory_is_backed_by_module_resources(self) -> None:
        inventory = markdown_table(markdown_section("What gets created"))
        documented = {row["Resource"]: row for row in inventory}
        module = (ROOT / "modules/vpc/main.tf").read_text(encoding="utf-8")
        expected_resources = {
            "VPC": [('aws_vpc', 'this')],
            "Internet Gateway": [('aws_internet_gateway', 'this')],
            "Public subnets": [('aws_subnet', 'public')],
            "Private subnets": [('aws_subnet', 'private')],
            "Database subnets": [('aws_subnet', 'database')],
            "NAT Gateways": [('aws_nat_gateway', 'this')],
            "Elastic IPs": [('aws_eip', 'nat')],
            "Route tables": [
                ('aws_route_table', 'public'),
                ('aws_route_table', 'private'),
                ('aws_route_table', 'database'),
            ],
            "RDS DB Subnet Group": [('aws_db_subnet_group', 'this')],
            "VPC Flow Logs": [('aws_flow_log', 'this')],
        }

        self.assertEqual(set(documented), set(expected_resources))
        for label, resources in expected_resources.items():
            with self.subTest(resource=label):
                for resource_type, resource_name in resources:
                    self.assertIn(f'resource "{resource_type}" "{resource_name}"', module)

        vpc = hcl_named_block(module, "resource", "aws_vpc", "this")
        public_subnet = hcl_named_block(module, "resource", "aws_subnet", "public")
        flow_log_group = hcl_named_block(
            module, "resource", "aws_cloudwatch_log_group", "flow_logs"
        )
        self.assertIn("enable_dns_hostnames = true", vpc)
        self.assertIn("enable_dns_support   = true", vpc)
        self.assertIn("map_public_ip_on_launch = true", public_subnet)
        self.assertIn("retention_in_days = 30", flow_log_group)


if __name__ == "__main__":
    unittest.main()

locals {
  effective_ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023[0].id
}

# ── AMI auto-resolution (skipped when ami_id is supplied) ────────────────────

data "aws_ami" "al2023" {
  count = var.ami_id == "" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ── IAM role ─────────────────────────────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# S3 read access for the deployment bucket
resource "aws_iam_role_policy" "s3_read" {
  name = "${var.name}-s3-read"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      Resource = [
        var.s3_bucket_arn,
        "${var.s3_bucket_arn}/*",
      ]
    }]
  })
}

# SSM Session Manager + CloudWatch agent managed policies
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ── Security group ────────────────────────────────────────────────────────────

resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-sg"
  description = "Web server: HTTP + HTTPS inbound, all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "All outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-ec2-sg" })
}

# ── CloudWatch log groups ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "system" {
  name              = "/ec2/${var.name}/system"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ec2/${var.name}/app"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ── EC2 instance ──────────────────────────────────────────────────────────────

resource "aws_instance" "web" {
  ami                  = local.effective_ami_id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.ec2.name
  key_name             = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.ec2.id]

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    name           = var.name
    s3_bucket_name = var.s3_bucket_name
    cw_system_log  = aws_cloudwatch_log_group.system.name
    cw_app_log     = aws_cloudwatch_log_group.app.name
    region         = data.aws_region.current.name
  })

  user_data_replace_on_change = true

  tags = merge(var.tags, { Name = "${var.name}-web" })
}

data "aws_region" "current" {}

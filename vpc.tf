# VPC wiring for canaries that need to reach internal/private endpoints.
#
# Per-canary opt-in: set vpc_enabled = true in the canary config (cue) to run
# that canary inside the AFT shared VPC. The SG below is intentionally
# permissive on egress (443 anywhere + DNS) because canaries must reach the
# Domino/API host AND AWS services (SSM for key resolution, S3 for artifacts,
# CloudWatch Logs, X-Ray) - all of which resolve to public IPs reached via NAT.
# No ingress rules: a canary never accepts connections.

# Workspace pattern (AGENTS.md rule 4): AFT provisions the shared VPC; leaf
# projects look it up via SSM /network/vpc_id + subnet tags.
data "aws_ssm_parameter" "vpc_id" {
  count = local.vpc_canary_count > 0 ? 1 : 0
  name  = "/network/vpc_id"
}

data "aws_vpc" "this" {
  count = local.vpc_canary_count > 0 ? 1 : 0
  id    = data.aws_ssm_parameter.vpc_id[0].value
}

data "aws_subnets" "private" {
  count = local.vpc_canary_count > 0 ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.vpc_id[0].value]
  }
  filter {
    name   = "tag:Name"
    values = ["aft-global-default-vpc-private"]
  }
}

# Canary security group - outbound only. Egress 443 to 0.0.0.0/0 because the
# canary reaches Domino/SSM/S3/Logs/X-Ray via NAT (their endpoints are public
# IPs). DNS egress to the VPC CIDR for name resolution.
resource "aws_security_group" "canary" {
  count       = local.vpc_canary_count > 0 ? 1 : 0
  name        = "synth-canary-vpc"
  description = "Synthetics canary VPC egress (created 2026-08-22)"
  vpc_id      = data.aws_ssm_parameter.vpc_id[0].value

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.this[0].cidr_block]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this[0].cidr_block]
  }

  tags = {
    Name    = "synth-canary-vpc"
    Purpose = "cloudwatch-synthetic-canary"
  }
}

locals {
  vpc_canary_count = length([for c in var.cloudwatch_map : c if c.vpc_enabled == true])

  # Shared vpc_config for all VPC-enabled canaries (same subnets + SG).
  canary_vpc_config = local.vpc_canary_count > 0 ? {
    subnet_ids         = data.aws_subnets.private[0].ids
    security_group_ids = [aws_security_group.canary[0].id]
  } : null
}

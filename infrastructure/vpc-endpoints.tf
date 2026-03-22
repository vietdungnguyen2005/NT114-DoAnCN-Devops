# ============================================================================
# VPC Endpoints — Reduce NAT Gateway traffic & cost
# ============================================================================
# S3 Gateway Endpoint: free, pods in private subnets access S3 without NAT.
# Saves egress cost for static asset uploads, Terraform state, logs, etc.
# ============================================================================

# ---------------------------------------------------------------------------
# Security Group for VPC Interface Endpoints (if needed in the future)
# ---------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.name}-vpce-"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = module.vpc.vpc_id

  tags = merge(local.tags, { Name = "${local.name}-vpce-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpce_from_vpc" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "HTTPS from VPC"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "vpce_all_out" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# S3 Gateway Endpoint — free, no NAT traffic cost for S3 access
# ---------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(local.tags, {
    Name = "${local.name}-s3-endpoint"
  })
}

# ============================================================================
# VPC — Mạng nội bộ an toàn cho TRAVEL-WEB
# Public Subnet + Private Subnet + Single NAT Gateway
# Mở rộng lên 2+ AZ khi cần EKS bằng cách tăng az_count
# ============================================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs = local.azs

  # Tính subnet CIDR tự động từ VPC CIDR
  # Public:  10.0.0.0/24, 10.0.1.0/24, ...
  # Private: 10.0.100.0/24, 10.0.101.0/24, ...
  public_subnets  = [for k in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets = [for k in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 8, k + 100)]

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Single NAT Gateway: tiết kiệm ~$45/tháng so với multi-AZ NAT
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Tags chuẩn bị sẵn cho EKS — không tốn thêm tiền
  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    Tier                                          = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    Tier                                          = "private"
  }

  tags = local.tags
}

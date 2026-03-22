# ============================================================================
# EKS — Amazon Kubernetes Cluster cho TRAVEL-WEB
# ============================================================================
# EKS yêu cầu tối thiểu 2 AZ → az_count đổi sang default = 2
# Worker Nodes chạy trong Private Subnet, dùng NAT Gateway để ra internet
# ============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cho phép user tạo cluster có quyền admin để dùng kubectl ngay
  enable_cluster_creator_admin_permissions = true

  # Mở public endpoint để thao tác từ máy local bằng kubectl
  # Giới hạn bằng IP nếu cần: cluster_endpoint_public_access_cidrs
  cluster_endpoint_public_access = true

  # --- EKS Add-ons (miễn phí, do AWS quản lý) ---
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # --- Worker Nodes ---
  eks_managed_node_groups = {
    worker_nodes = {
      instance_types = [var.node_instance_type]
      capacity_type  = var.node_capacity_type # ON_DEMAND hoặc SPOT

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Disk cho worker nodes
      disk_size = 20 # GB — đủ cho Docker images

      labels = {
        role = "worker"
      }

      # Security — chặn access metadata endpoint IMDSv1
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required" # Bắt buộc IMDSv2
        http_put_response_hop_limit = 1
      }
    }
  }

  # Cho phép EKS nodes truy cập RDS
  node_security_group_additional_rules = {
    egress_rds = {
      description                   = "Worker nodes to RDS PostgreSQL"
      protocol                      = "tcp"
      from_port                     = 5432
      to_port                       = 5432
      type                          = "egress"
      source_cluster_security_group = false
      cidr_blocks                   = [var.vpc_cidr]
    }
  }

  tags = local.tags
}

# --- IAM Role cho EKS Nodes truy cập ECR (pull images) ---
# Module EKS đã tự tạo role với AmazonEKSWorkerNodePolicy,
# AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly.
# Không cần thêm policy nào.

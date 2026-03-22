# ============================================================================
# Variables — Biến cấu hình cho TRAVEL-WEB Infrastructure
# ============================================================================

# --- General ---

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-1"
}

variable "name" {
  type        = string
  description = "Project name prefix for all resources"
  default     = "travel-web"
}

variable "tags" {
  type        = map(string)
  description = "Extra tags to apply to all resources"
  default     = {}
}

# --- VPC ---

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones (EKS yêu cầu >= 2)"
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "az_count must be between 2 and 6 (EKS requires at least 2 AZs)."
  }
}

variable "azs" {
  type        = list(string)
  description = "Explicit AZ list (e.g. [\"ap-southeast-1a\"]). If set, overrides az_count."
  default     = []
}

# --- ECR ---

variable "ecr_force_delete" {
  type        = bool
  description = "Allow Terraform to delete ECR repos even if they contain images"
  default     = false
}

# --- S3 ---

variable "static_assets_bucket_name" {
  type        = string
  description = "Override S3 bucket name for static assets (must be globally unique). Leave empty to auto-generate."
  default     = ""
}

variable "s3_force_destroy" {
  type        = bool
  description = "Allow Terraform to delete S3 bucket even if it contains objects"
  default     = false
}

# --- EKS ---

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.30"
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type for EKS worker nodes (t3.medium = 2vCPU/4GB, t3.large = 2vCPU/8GB)"
  default     = "t3.medium"
}

variable "node_capacity_type" {
  type        = string
  description = "ON_DEMAND (ổn định) hoặc SPOT (tiết kiệm ~70% nhưng có thể bị thu hồi)"
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 3
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of worker nodes on initial create"
  default     = 1
}

# --- RDS PostgreSQL ---

variable "rds_engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "16.4"
}

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class (db.t4g.micro = free-tier eligible, db.t4g.small = production nhẹ)"
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  type        = number
  description = "Initial storage in GB"
  default     = 20
}

variable "rds_max_allocated_storage" {
  type        = number
  description = "Max storage autoscaling in GB (0 = disable autoscaling)"
  default     = 50
}

variable "rds_db_name" {
  type        = string
  description = "Default database name"
  default     = "travelweb"
}

variable "rds_username" {
  type        = string
  description = "Master username for RDS"
  default     = "travelweb_admin"
  sensitive   = true
}

variable "rds_password" {
  type        = string
  description = "Master password for RDS (sẽ hỏi khi terraform apply nếu không set)"
  sensitive   = true
}

variable "rds_deletion_protection" {
  type        = bool
  description = "Bật/tắt deletion protection (tắt để dễ destroy khi dev)"
  default     = false
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot khi destroy (true cho dev, false cho prod)"
  default     = true
}

# --- ArgoCD ---

variable "argocd_chart_version" {
  type        = string
  description = "Helm chart version for argo-cd (https://github.com/argoproj/argo-helm)"
  default     = "7.7.5"
}

variable "argocd_app_name" {
  type        = string
  description = "Name of the bootstrap ArgoCD Application"
  default     = "travel-web"
}

variable "argocd_repo_url" {
  type        = string
  description = "Git repository URL containing K8s manifests for ArgoCD to sync"
  default     = "https://github.com/my-org/travel-web-manifests.git"
}

variable "argocd_repo_revision" {
  type        = string
  description = "Git branch / tag / commit to track"
  default     = "main"
}

variable "argocd_repo_path" {
  type        = string
  description = "Path inside the repo where manifests live"
  default     = "environments/dev"
}

variable "argocd_target_namespace" {
  type        = string
  description = "Kubernetes namespace that ArgoCD syncs manifests into"
  default     = "app"
}

# --- Traefik Ingress ---

variable "traefik_chart_version" {
  type        = string
  description = "Helm chart version for Traefik (https://github.com/traefik/traefik-helm-chart)"
  default     = "28.3.0"
}

# --- Secrets Manager ---

variable "secrets_recovery_window" {
  type        = number
  description = "Number of days before a secret is permanently deleted (0 = immediate, 7-30 for recovery)"
  default     = 7
}

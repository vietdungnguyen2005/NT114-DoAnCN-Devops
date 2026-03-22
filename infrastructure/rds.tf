# ============================================================================
# RDS — Amazon PostgreSQL Database cho TRAVEL-WEB
# ============================================================================
# PostgreSQL nằm trong Private Subnet, chỉ EKS Worker Nodes mới truy cập được.
# Lưu trữ: hotels, rooms, bookings, users, payments, reviews, v.v.
# ============================================================================

# --- Subnet Group: đặt RDS vào Private Subnets ---
resource "aws_db_subnet_group" "main" {
  name        = "${local.name}-db-subnet"
  description = "Private subnets for RDS PostgreSQL"
  subnet_ids  = module.vpc.private_subnets

  tags = merge(local.tags, { Name = "${local.name}-db-subnet" })
}

# --- RDS PostgreSQL Instance ---
resource "aws_db_instance" "postgres" {
  identifier = "${local.name}-postgres"

  # Engine
  engine               = "postgres"
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Storage
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database
  db_name  = var.rds_db_name
  username = var.rds_username
  password = var.rds_password
  port     = 5432

  # Network — Private Subnet only
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false # Single AZ tiết kiệm tiền, bật khi cần HA

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00" # UTC — 10:00-11:00 SGT
  maintenance_window      = "sun:04:00-sun:05:00"

  # Protection
  deletion_protection       = var.rds_deletion_protection
  skip_final_snapshot       = var.rds_skip_final_snapshot
  final_snapshot_identifier = var.rds_skip_final_snapshot ? null : "${local.name}-postgres-final-${formatdate("YYYYMMDD", timestamp())}"

  # Monitoring
  performance_insights_enabled = false # Tắt để tiết kiệm (bật khi debug perf)

  # Logging
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(local.tags, { Name = "${local.name}-postgres" })
}

# --- Parameter Group: tối ưu PostgreSQL cho travel-web workload ---
resource "aws_db_parameter_group" "postgres" {
  name_prefix = "${local.name}-pg-"
  family      = "postgres${split(".", var.rds_engine_version)[0]}" # postgres16

  description = "Custom parameters for ${local.name}"

  # Log slow queries (> 1 giây)
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  # Timezone cho app
  parameter {
    name  = "timezone"
    value = "Asia/Ho_Chi_Minh"
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

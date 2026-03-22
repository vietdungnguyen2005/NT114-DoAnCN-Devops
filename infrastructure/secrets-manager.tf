# ============================================================================
# AWS Secrets Manager — Centralized Secret Storage for TRAVEL-WEB
# ============================================================================
# Stores sensitive configuration that the Next.js app and other services need:
#   - Database credentials (RDS connection string)
#   - Application secrets (JWT secret, session keys, API keys)
#   - External service credentials (payment gateway, email service, etc.)
#
# Secrets are injected into EKS pods via:
#   - AWS Secrets and Configuration Provider (ASCP) for CSI driver
#   - Or External Secrets Operator syncing to K8s Secrets
# ============================================================================

# ---------------------------------------------------------------------------
# 1. Application Secrets — General app config
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${local.name}/app-secrets"
  description             = "Application secrets for ${local.name} (JWT, session, API keys)"
  recovery_window_in_days = var.secrets_recovery_window

  tags = merge(local.tags, {
    Name      = "${local.name}-app-secrets"
    Component = "application"
  })
}

# Initial placeholder values — update via AWS Console or CLI after creation
resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    NEXTAUTH_SECRET     = "CHANGE_ME_AFTER_DEPLOY"
    NEXTAUTH_URL        = "https://travel-web.example.com"
    JWT_SECRET          = "CHANGE_ME_AFTER_DEPLOY"
    SESSION_SECRET      = "CHANGE_ME_AFTER_DEPLOY"
    PAYMENT_GATEWAY_KEY = "CHANGE_ME_AFTER_DEPLOY"
    EMAIL_SERVICE_KEY   = "CHANGE_ME_AFTER_DEPLOY"
    S3_BUCKET_NAME      = "pending-terraform-output"
  })

  lifecycle {
    ignore_changes = [secret_string] # Không ghi đè khi update bằng tay
  }
}

# ---------------------------------------------------------------------------
# 2. Database Credentials — RDS connection details
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.name}/db-credentials"
  description             = "RDS PostgreSQL credentials for ${local.name}"
  recovery_window_in_days = var.secrets_recovery_window

  tags = merge(local.tags, {
    Name      = "${local.name}-db-credentials"
    Component = "database"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    DB_HOST     = aws_db_instance.postgres.address
    DB_PORT     = tostring(aws_db_instance.postgres.port)
    DB_NAME     = var.rds_db_name
    DB_USERNAME = var.rds_username
    DB_PASSWORD = var.rds_password
    DATABASE_URL = "postgresql://${var.rds_username}:${var.rds_password}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${var.rds_db_name}"
  })

  lifecycle {
    ignore_changes = [secret_string] # Không ghi đè khi rotate password
  }
}

# ---------------------------------------------------------------------------
# 3. IAM Role (IRSA) — Allow EKS pods to read secrets
# ---------------------------------------------------------------------------
resource "aws_iam_role" "secrets_reader" {
  name = "${local.name}-secrets-reader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
            "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.app_namespace}:${local.app_sa_name}"
          }
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "secrets_reader" {
  name        = "${local.name}-secrets-reader"
  description = "Allow reading secrets from Secrets Manager for ${local.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = [
          aws_secretsmanager_secret.app_secrets.arn,
          aws_secretsmanager_secret.db_credentials.arn,
        ]
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "secrets_reader" {
  role       = aws_iam_role.secrets_reader.name
  policy_arn = aws_iam_policy.secrets_reader.arn
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "secrets_reader_role_arn" {
  value       = aws_iam_role.secrets_reader.arn
  description = "IAM Role ARN for pods to read Secrets Manager (annotate K8s ServiceAccount)"
}

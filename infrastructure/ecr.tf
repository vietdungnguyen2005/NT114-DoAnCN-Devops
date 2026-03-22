# ============================================================================
# ECR — Docker Image Registry (Single Repo for Next.js Monolith)
# ============================================================================

resource "aws_ecr_repository" "app" {
  name         = "${local.name}-app"
  force_delete = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.tags
}

# --- Lifecycle Policy: tự xóa image cũ để tiết kiệm dung lượng ---

resource "aws_ecr_lifecycle_policy" "app_lifecycle" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

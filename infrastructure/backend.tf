# ============================================================================
# S3 Backend for Terraform State
# ============================================================================
# Bỏ comment sau khi chạy bootstrap:
#   cd infrastructure/bootstrap && terraform init && terraform apply
# Rồi chạy:
#   cd infrastructure && terraform init -migrate-state
# ============================================================================

# terraform {
#   backend "s3" {
#     bucket         = "travel-web-terraform-state"
#     key            = "infrastructure/terraform.tfstate"
#     region         = "ap-southeast-1"
#     dynamodb_table = "travel-web-terraform-lock"
#     encrypt        = true
#   }
# }

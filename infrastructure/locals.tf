# ============================================================================
# Local Values
# ============================================================================

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  name         = var.name
  cluster_name = "${var.name}-eks"

  # Suy ra AZ từ region + chữ cái (vd: ap-southeast-1a)
  # Nếu cần tùy biến, set var.azs trực tiếp
  az_letters = ["a", "b", "c", "d", "e", "f"]
  azs        = length(var.azs) > 0 ? var.azs : [for i in range(var.az_count) : "${var.aws_region}${local.az_letters[i]}"]

  static_assets_bucket_name = var.static_assets_bucket_name != "" ? var.static_assets_bucket_name : "${var.name}-static-assets-${random_string.suffix.result}"

  tags = merge(
    {
      Project = var.name
    },
    var.tags
  )
}

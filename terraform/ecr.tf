resource "aws_ecr_repository" "luxe_repo" {
  name                 = "luxe-jewelry-store-project"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project   = "LuxeJewelry"
    Owner     = "Luxe"
    ManagedBy = "Terraform"
    FinOps    = "True"
  }
}


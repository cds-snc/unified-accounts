resource "aws_ecr_repository" "idp_login_pr" {
  name                 = "idp-login-pr"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = var.common_tags
}

resource "aws_ecr_lifecycle_policy" "idp_login_pr" {
  repository = aws_ecr_repository.idp_login_pr.name
  policy     = var.ecr_policy
}
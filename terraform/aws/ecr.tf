resource "aws_ecr_repository" "idp" {
  name                 = "idp"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "idp" {
  repository = aws_ecr_repository.idp.name
  policy     = file("${path.module}/ecr-lifecycle.json")
}

resource "aws_ecr_repository" "idp_login" {
  name                 = "idp-login"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "idp_login" {
  repository = aws_ecr_repository.idp_login.name
  policy     = file("${path.module}/ecr-lifecycle.json")
}

resource "aws_ecr_repository" "idp_login_pr" {
  count = var.env == "staging" ? 1 : 0

  name                 = "idp-login-pr"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "idp_login_pr" {
  count = var.env == "staging" ? 1 : 0

  repository = aws_ecr_repository.idp_login_pr[0].name
  policy     = file("${path.module}/ecr-lifecycle.json")
}

resource "aws_ecr_repository" "idp_event_exporter" {
  name                 = "idp-event-exporter"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "idp_event_exporter" {
  repository = aws_ecr_repository.idp_event_exporter.name
  policy     = file("${path.module}/ecr-lifecycle.json")
}

resource "aws_ecr_repository" "idp_load_test" {
  name                 = "idp-load-test"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "idp_load_test" {
  repository = aws_ecr_repository.idp_load_test.name
  policy     = file("${path.module}/ecr-lifecycle.json")
}

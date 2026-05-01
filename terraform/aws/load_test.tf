#
# ECS task definition to run k6 load tests against the IdP in staging.
#
module "load_test" {
  count  = var.env == "staging" ? 1 : 0
  source = "./load_test"
  region = var.region

  idp_domain                = var.domain
  idp_load_test_client_id   = var.idp_load_test_client_id
  idp_load_test_username    = var.idp_load_test_username
  idp_load_test_password    = var.idp_load_test_password
  idp_load_test_totp_secret = var.idp_load_test_totp_secret

  ecr_policy  = file("${path.module}/ecr-lifecycle.json")
  common_tags = local.common_tags
}

moved {
  from = aws_ecr_repository.idp_load_test
  to   = module.load_test.aws_ecr_repository.idp_load_test
}

moved {
  from = aws_ecr_lifecycle_policy.idp_load_test
  to   = module.load_test.aws_ecr_lifecycle_policy.idp_load_test
}

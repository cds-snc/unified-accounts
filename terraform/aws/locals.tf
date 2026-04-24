locals {
  cbs_satellite_bucket_arn    = "arn:aws:s3:::${var.cbs_satellite_bucket_name}"
  vpc_az_count                = 2
  pr_review_env_ssm_param_arn = "arn:aws:ssm:${var.region}:${var.account_id}:parameter/idp-login-pr/env"
  protocol_versions           = toset(["HTTP1", "HTTP2"])
  vpc_interface_endpoints     = toset(["ecs", "logs", "rds", "ssm"])
  vpc_gateway_endpoints       = toset(["s3"])

  common_tags = {
    Terraform  = "true"
    CostCentre = var.billing_tag_value
  }
}
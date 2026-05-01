module "pr_review" {
  count  = var.env == "staging" ? 1 : 0
  source = "./pr_review"

  region     = var.region
  account_id = var.account_id

  pr_review_env_ssm_params_get = [
    aws_ssm_parameter.idp_loginclient_machine_username.arn,
    aws_ssm_parameter.idp_loginclient_pat.arn,
    aws_ssm_parameter.idp_zitadel_org.arn,
    aws_ssm_parameter.idp_notify_api_key.arn,
    aws_ssm_parameter.idp_notify_template_id.arn,
  ]

  ecr_policy        = file("${path.module}/ecr-lifecycle.json")
  billing_tag_value = var.billing_tag_value
  common_tags       = local.common_tags
}

moved {
  from = aws_iam_role.idp_login_pr[0]
  to   = module.pr_review[0].aws_iam_role.idp_login_pr
}

moved {
  from = aws_iam_policy.idp_login_pr_ssm_params[0]
  to   = module.pr_review[0].aws_iam_policy.idp_login_pr_ssm_params
}

moved {
  from = module.github_workflow_roles[0].aws_iam_role.this["platform-unified-accounts-user-portal-pr-review-deploy"]
  to   = module.pr_review[0].module.github_workflow_roles.aws_iam_role.this["platform-unified-accounts-user-portal-pr-review-deploy"]
}

moved {
  from = module.github_workflow_roles[0].aws_iam_role.this["platform-unified-accounts-user-portal-pr-review-delete-unused"]
  to   = module.pr_review[0].module.github_workflow_roles.aws_iam_role.this["platform-unified-accounts-user-portal-pr-review-delete-unused"]
}

moved {
  from = module.github_workflow_roles[0].aws_iam_role.this["platform-unified-accounts-pr-review-get-vars"]
  to   = module.pr_review[0].module.github_workflow_roles.aws_iam_role.this["platform-unified-accounts-pr-review-get-vars"]
}

moved {
  from = aws_iam_role_policy_attachment.pr_review_get_vars[0]
  to   = module.pr_review[0].aws_iam_role_policy_attachment.pr_review_get_vars
}

moved {
  from = aws_iam_role_policy_attachment.pr_review_deploy[0]
  to   = module.pr_review[0].aws_iam_role_policy_attachment.pr_review_deploy
}

moved {
  from = aws_iam_role_policy_attachment.pr_review_delete_unused[0]
  to   = module.pr_review[0].aws_iam_role_policy_attachment.pr_review_delete_unused
}

moved {
  from = aws_iam_role_policy_attachment.idp_login_pr_vpc_access[0]
  to   = module.pr_review[0].aws_iam_role_policy_attachment.idp_login_pr_vpc_access
}

moved {
  from = aws_iam_role_policy_attachment.idp_login_pr_ssm_params[0]
  to   = module.pr_review[0].aws_iam_role_policy_attachment.idp_login_pr_ssm_params
}

moved {
  from = aws_iam_role.idp_login_pr[0]
  to   = module.pr_review[0].aws_iam_role.idp_login_pr
}

moved {
  from = aws_iam_policy.pr_review_get_vars[0]
  to   = module.pr_review[0].aws_iam_policy.pr_review_get_vars
}

moved {
  from = aws_iam_policy.pr_review_deploy[0]
  to   = module.pr_review[0].aws_iam_policy.pr_review_deploy
}

moved {
  from = aws_iam_policy.pr_review_delete_unused[0]
  to   = module.pr_review[0].aws_iam_policy.pr_review_delete_unused
}

moved {
  from = aws_iam_policy.idp_login_pr_ssm_params[0]
  to   = module.pr_review[0].aws_iam_policy.idp_login_pr_ssm_params
}

moved {
  from = aws_ecr_repository.idp_login_pr[0]
  to   = module.pr_review[0].aws_ecr_repository.idp_login_pr
}

moved {
  from = aws_ecr_lifecycle_policy.idp_login_pr[0]
  to   = module.pr_review[0].aws_ecr_lifecycle_policy.idp_login_pr
}
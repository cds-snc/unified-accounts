locals {
  pr_review_delete_unused = "platform-unified-accounts-user-portal-pr-review-delete-unused"
  pr_review_deploy        = "platform-unified-accounts-user-portal-pr-review-deploy"
  pr_review_get_vars      = "platform-unified-accounts-pr-review-get-vars"
}

#
# Create the OIDC roles used by the GitHub workflows
# The roles can be assumed by the GitHub workflows according to the `claim`
# attribute of each role.
# 
module "github_workflow_roles" {
  count  = var.env == "staging" ? 1 : 0
  source = "github.com/cds-snc/terraform-modules//gh_oidc_role?ref=v10.11.4"

  roles = [
    {
      name      = local.pr_review_delete_unused
      repo_name = "platform-unified-accounts-user-portal"
      claim     = "ref:refs/heads/main"
    },
    {
      name      = local.pr_review_deploy
      repo_name = "platform-unified-accounts-user-portal"
      claim     = "pull_request"
    },
    {
      name      = local.pr_review_get_vars
      repo_name = "platform-unified-accounts"
      claim     = "ref:refs/heads/main"
    }
  ]

  billing_tag_value = var.billing_tag_value
}

#
# Create and Manage PR review environment resources
#
resource "aws_iam_role_policy_attachment" "pr_review_deploy" {
  count      = var.env == "staging" ? 1 : 0
  role       = local.pr_review_deploy
  policy_arn = aws_iam_policy.pr_review_deploy[0].arn

  depends_on = [module.github_workflow_roles[0]]
}

resource "aws_iam_policy" "pr_review_deploy" {
  count  = var.env == "staging" ? 1 : 0
  name   = local.pr_review_deploy
  path   = "/"
  policy = data.aws_iam_policy_document.pr_review_deploy[0].json
}

#trivy:ignore:AWS-0342
data "aws_iam_policy_document" "pr_review_deploy" {
  count = var.env == "staging" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "lambda:AddPermission",
      "lambda:CreateFunction",
      "lambda:CreateFunctionUrlConfig",
      "lambda:DeleteFunction",
      "lambda:DeleteFunctionUrlConfig",
      "lambda:DeleteFunctionConcurrency",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:GetFunctionUrlConfig",
      "lambda:ListFunctionUrlConfigs",
      "lambda:PutFunctionConcurrency",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateFunctionUrlConfig"
    ]
    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:idp-login-pr-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.idp_login_pr[0].arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream",
      "logs:DeleteRetentionPolicy",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/idp-login-pr-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchDeleteImage",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [
      aws_ecr_repository.idp_login_pr[0].arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }
}

#
# Delete unused PR review environment resources
#
resource "aws_iam_role_policy_attachment" "pr_review_delete_unused" {
  count = var.env == "staging" ? 1 : 0

  role       = local.pr_review_delete_unused
  policy_arn = aws_iam_policy.pr_review_delete_unused[0].arn

  depends_on = [module.github_workflow_roles[0]]
}

resource "aws_iam_policy" "pr_review_delete_unused" {
  count = var.env == "staging" ? 1 : 0

  name   = local.pr_review_delete_unused
  path   = "/"
  policy = data.aws_iam_policy_document.pr_review_delete_unused[0].json
}

#trivy:ignore:AWS-0342
data "aws_iam_policy_document" "pr_review_delete_unused" {
  count = var.env == "staging" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "lambda:ListFunctions"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "lambda:DeleteFunction",
      "lambda:DeleteFunctionUrlConfig",
      "lambda:DeleteFunctionConcurrency",
    ]
    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:idp-login-pr-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream",
      "logs:DeleteRetentionPolicy",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/idp-login-pr-*"
    ]
  }
}

#
# Get env vars from IdP login task definition for PR review environments
#
resource "aws_iam_role_policy_attachment" "pr_review_get_vars" {
  count = var.env == "staging" ? 1 : 0

  role       = local.pr_review_get_vars
  policy_arn = aws_iam_policy.pr_review_get_vars[0].arn

  depends_on = [module.github_workflow_roles[0]]
}

resource "aws_iam_policy" "pr_review_get_vars" {
  count = var.env == "staging" ? 1 : 0

  name   = local.pr_review_get_vars
  path   = "/"
  policy = data.aws_iam_policy_document.pr_review_get_vars[0].json
}

data "aws_iam_policy_document" "pr_review_get_vars" {
  count = var.env == "staging" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ecs:ListTasks"
    ]
    resources = [
      "arn:aws:ecs:${var.region}:${var.account_id}:container-instance/idp/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeTasks"
    ]
    resources = [
      "arn:aws:ecs:${var.region}:${var.account_id}:cluster/idp",
      "arn:aws:ecs:${var.region}:${var.account_id}:task/idp/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.idp_loginclient_machine_username.arn,
      aws_ssm_parameter.idp_loginclient_pat.arn,
      aws_ssm_parameter.idp_zitadel_org.arn,
      aws_ssm_parameter.idp_notify_api_key.arn,
      aws_ssm_parameter.idp_notify_template_id.arn,
      local.pr_review_env_ssm_param_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:PutParameter"
    ]
    resources = [
      local.pr_review_env_ssm_param_arn
    ]
  }
}
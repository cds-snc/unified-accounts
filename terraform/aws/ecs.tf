locals {
  container_env = [
    {
      "name"  = "ZITADEL_EXTERNALDOMAIN",
      "value" = var.domain
    },
  ]
  container_secrets = [
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_DATABASE"
      "valueFrom" = aws_ssm_parameter.idp_database.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_HOST"
      "valueFrom" = aws_ssm_parameter.idp_database_host.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_USER_USERNAME"
      "valueFrom" = aws_ssm_parameter.idp_database_username.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_USER_PASSWORD"
      "valueFrom" = aws_ssm_parameter.idp_database_password.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME"
      "valueFrom" = aws_ssm_parameter.idp_database_admin_username.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD"
      "valueFrom" = aws_ssm_parameter.idp_database_admin_password.arn
    },
    {
      "name"      = "ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME"
      "valueFrom" = aws_ssm_parameter.idp_admin_username.arn
    },
    {
      "name"      = "ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD"
      "valueFrom" = aws_ssm_parameter.idp_admin_password.arn
    },
    {
      "name"      = "ZITADEL_MASTERKEY"
      "valueFrom" = aws_ssm_parameter.idp_secret_key.arn
    },
  ]
}

module "idp_ecs" {
  source = "github.com/cds-snc/terraform-modules//ecs?ref=v10.10.2"

  cluster_name     = "idp"
  service_name     = "idp"
  task_cpu         = var.idp_task_cpu
  task_memory      = var.idp_task_memory
  cpu_architecture = "ARM64"

  cluster_capacity_provider      = var.idp_cluster_capacity_provider
  service_use_latest_task_def    = true
  container_image_track_deployed = true

  # Scaling
  enable_autoscaling       = true
  desired_count            = var.idp_task_desired_count
  autoscaling_min_capacity = var.idp_task_min_capacity
  autoscaling_max_capacity = var.idp_task_max_capacity

  # Task definition
  container_image                     = "${aws_ecr_repository.idp.repository_url}:latest"
  container_command                   = ["start-from-init", "--masterkeyFromEnv", "--tlsMode", "enabled", "--config", "/app/config.yaml", "--steps", "/app/steps.yaml"]
  container_host_port                 = 8080
  container_port                      = 8080
  container_environment               = local.container_env
  container_secrets                   = local.container_secrets
  container_read_only_root_filesystem = false
  task_exec_role_policy_documents = [
    data.aws_iam_policy_document.ecs_task_ssm_parameters.json
  ]

  lb_target_group_arns = [
    for protocol_version in local.protocol_versions : {
      target_group_arn = aws_lb_target_group.idp[protocol_version].arn
      container_name   = "idp"
      container_port   = 8080
    }
  ]
  subnet_ids         = module.idp_vpc.private_subnet_ids
  security_group_ids = [aws_security_group.idp_ecs.id]

  billing_tag_value = var.billing_tag_value
}

#
# IAM policies
#
data "aws_iam_policy_document" "ecs_task_ssm_parameters" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.idp_admin_username.arn,
      aws_ssm_parameter.idp_admin_password.arn,
      aws_ssm_parameter.idp_database.arn,
      aws_ssm_parameter.idp_database_host.arn,
      aws_ssm_parameter.idp_database_username.arn,
      aws_ssm_parameter.idp_database_password.arn,
      aws_ssm_parameter.idp_database_admin_username.arn,
      aws_ssm_parameter.idp_database_admin_password.arn,
      aws_ssm_parameter.idp_secret_key.arn
    ]
  }
}

#
# SSM Parameters
#
resource "aws_ssm_parameter" "idp_secret_key" {
  name  = "idp_secret_key"
  type  = "SecureString"
  value = var.idp_secret_key
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "idp_admin_username" {
  name  = "idp_admin_username"
  type  = "SecureString"
  value = var.idp_admin_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "idp_admin_password" {
  name  = "idp_admin_password"
  type  = "SecureString"
  value = var.idp_admin_password
  tags  = local.common_tags
}

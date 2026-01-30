module "schedule_shutdown" {
  count = var.env == "staging" ? 1 : 0

  source = "github.com/cds-snc/terraform-modules//schedule_shutdown?ref=v10.10.2"

  ecs_service_arns = [
    module.idp_ecs.service_id,
    module.login_ecs.service_id,
  ]

  schedule_shutdown = "cron(0 23 * * ? *)"       # 11pm UTC, every day
  schedule_startup  = "cron(0 11 ? * MON-FRI *)" # 11am UTC, Monday-Friday

  billing_tag_value = var.billing_tag_value
}

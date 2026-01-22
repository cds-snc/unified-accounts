locals {
  billing_tag_value = "${local.env_vars.inputs.product_name}-${local.env_vars.inputs.env}"
  env_vars          = read_terragrunt_config("./env_vars.hcl")
}

inputs = {
  account_id                = local.env_vars.inputs.account_id
  billing_tag_value         = local.billing_tag_value
  cbs_satellite_bucket_name = "cbs-satellite-${local.env_vars.inputs.account_id}"
  domain                    = local.env_vars.inputs.domain
  env                       = local.env_vars.inputs.env
  product_name              = local.env_vars.inputs.product_name
  region                    = local.env_vars.inputs.region
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file("./common/provider.tf")
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    encrypt             = true
    bucket              = "${local.billing_tag_value}-tf"
    use_lockfile        = true
    region              = "ca-central-1"
    key                 = "terraform.tfstate"
    s3_bucket_tags      = { CostCenter : local.billing_tag_value }
  }
}
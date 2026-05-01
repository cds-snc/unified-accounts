resource "aws_ssm_parameter" "idp_load_test_client_id" {
  name  = "idp_load_test_client_id"
  type  = "SecureString"
  value = var.idp_load_test_client_id
  tags  = var.common_tags
}

resource "aws_ssm_parameter" "idp_load_test_username" {
  name  = "idp_load_test_username"
  type  = "SecureString"
  value = var.idp_load_test_username
  tags  = var.common_tags
}

resource "aws_ssm_parameter" "idp_load_test_password" {
  name  = "idp_load_test_password"
  type  = "SecureString"
  value = var.idp_load_test_password
  tags  = var.common_tags
}

resource "aws_ssm_parameter" "idp_load_test_totp_secret" {
  name  = "idp_load_test_totp_secret"
  type  = "SecureString"
  value = var.idp_load_test_totp_secret
  tags  = var.common_tags
}
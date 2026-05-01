variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "ecr_policy" {
  description = "The ECR lifecycle policy JSON content"
  type        = string
}

variable "idp_domain" {
  description = "The IdP domain to use for the load test"
  type        = string
}

variable "idp_load_test_client_id" {
  description = "The Zitadel client ID for the IdP load test."
  type        = string
  sensitive   = true
}

variable "idp_load_test_password" {
  description = "The password for the IdP load test user."
  type        = string
  sensitive   = true
}

variable "idp_load_test_totp_secret" {
  description = "The TOTP secret for the IdP load test user."
  type        = string
  sensitive   = true
}

variable "idp_load_test_username" {
  description = "The username for the IdP load test user."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

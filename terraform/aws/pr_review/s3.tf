module "integration_test_results" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=v11.2.2"
  bucket_name       = "platform-unified-accounts-integration-tests-${var.env}"
  billing_tag_value = var.billing_tag_value

  lifecycle_rule = [
    {
      id      = "expire_all"
      enabled = true
      expiration = {
        days = "14"
      }
    },
    {
      id                                     = "remove_noncurrent_versions"
      enabled                                = true
      abort_incomplete_multipart_upload_days = "7"
      noncurrent_version_expiration = {
        days = "14"
      }
    }
  ]

  versioning = {
    enabled = true
  }
}
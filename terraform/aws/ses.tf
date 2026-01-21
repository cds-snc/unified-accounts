#
# Allows idp to send email using a SES SMTP server
#
resource "aws_ses_domain_identity" "idp" {
  domain = aws_route53_zone.idp.name
}

resource "aws_route53_record" "idp_verification_TXT" {
  zone_id = aws_route53_zone.idp.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.idp.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.idp.verification_token]
}

resource "aws_ses_domain_identity_verification" "ses_verif" {
  domain     = aws_ses_domain_identity.idp.id
  depends_on = [aws_route53_record.idp_verification_TXT]
}

resource "aws_iam_user" "idp_send_email" {
  name = "idp_send_email"
}

data "aws_iam_policy_document" "idp_send_email" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendRawEmail"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "idp_send_email" {
  name   = "idp_send_email"
  policy = data.aws_iam_policy_document.idp_send_email.json
}

resource "aws_iam_group" "idp_send_email" {
  name = "idp_send_email"
}

resource "aws_iam_group_policy_attachment" "idp_send_email" {
  group      = aws_iam_group.idp_send_email.name
  policy_arn = aws_iam_policy.idp_send_email.arn
}

resource "aws_iam_user_group_membership" "idp_send_email" {
  user = aws_iam_user.idp_send_email.name
  groups = [
    aws_iam_group.idp_send_email.name
  ]
}

resource "aws_iam_access_key" "idp_send_email" {
  user = aws_iam_user.idp_send_email.name
}

output "smtp_username" {
  value = aws_iam_access_key.idp_send_email.id
}

output "smtp_password" {
  sensitive = true
  value     = aws_iam_access_key.idp_send_email.ses_smtp_password_v4
}

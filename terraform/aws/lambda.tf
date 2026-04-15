resource "aws_iam_role" "idp_login_pr" {
  count = var.env == "staging" ? 1 : 0

  name               = "idp-login-pr"
  assume_role_policy = data.aws_iam_policy_document.idp_login_pr[0].json
}

data "aws_iam_policy_document" "idp_login_pr" {
  count = var.env == "staging" ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "idp_login_pr_vpc_access" {
  count = var.env == "staging" ? 1 : 0

  role       = aws_iam_role.idp_login_pr[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

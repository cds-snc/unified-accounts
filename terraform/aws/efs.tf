resource "aws_efs_file_system" "idp" {

  encrypted = true
  tags      = local.common_tags
}

resource "aws_efs_file_system_policy" "idp" {
  file_system_id = aws_efs_file_system.idp.id
  policy         = data.aws_iam_policy_document.efs_access_point_secure.json
}

data "aws_iam_policy_document" "efs_access_point_secure" {
  statement {
    sid    = "AllowAccessThroughAccessPoint"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = [aws_efs_file_system.idp.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values = [
        aws_efs_access_point.idp.arn
      ]
    }
  }

  statement {
    sid       = "DenyNonSecureTransport"
    effect    = "Deny"
    actions   = ["*"]
    resources = [aws_efs_file_system.idp.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_efs_backup_policy" "idp" {
  file_system_id = aws_efs_file_system.idp.id
  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "idp" {
  count = local.vpc_az_count

  file_system_id = aws_efs_file_system.idp.id
  subnet_id      = element(module.idp_vpc.private_subnet_ids, count.index)
  security_groups = [
    aws_security_group.idp_efs.id
  ]
}

resource "aws_efs_access_point" "idp" {
  file_system_id = aws_efs_file_system.idp.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/idp"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
  tags = local.common_tags
}
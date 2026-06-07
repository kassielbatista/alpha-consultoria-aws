data "aws_partition" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "uploads" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "api" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = var.role_name
  })
}

resource "aws_iam_role_policy" "api_uploads" {
  name = "${var.role_name}-uploads"
  role = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = aws_s3_bucket.uploads.arn
      },
      {
        Sid    = "ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_ses" {
  count = var.enable_ses ? 1 : 0
  name  = "${var.role_name}-ses"
  role  = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SendEmail"
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.ses_domain_name}"
      }
    ]
  })
}

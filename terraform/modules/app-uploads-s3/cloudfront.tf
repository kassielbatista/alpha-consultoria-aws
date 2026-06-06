data "aws_caller_identity" "current" {}

locals {
  enable_cdn = var.cdn_domain_name != "" && var.acm_certificate_arn != ""
}

resource "aws_cloudfront_origin_access_control" "uploads" {
  count = local.enable_cdn ? 1 : 0

  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "uploads" {
  count = local.enable_cdn ? 1 : 0

  enabled             = true
  comment             = "${var.bucket_name} uploads CDN"
  default_root_object = ""
  price_class         = "PriceClass_All"
  aliases             = [var.cdn_domain_name]

  origin {
    domain_name              = aws_s3_bucket.uploads.bucket_regional_domain_name
    origin_id                = "s3-uploads"
    origin_access_control_id = aws_cloudfront_origin_access_control.uploads[0].id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-uploads"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name = "${var.bucket_name}-cdn"
  })
}

resource "aws_s3_bucket_policy" "cloudfront" {
  count = local.enable_cdn ? 1 : 0

  bucket = aws_s3_bucket.uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontRead"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.uploads.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.uploads[0].arn
          }
        }
      }
    ]
  })
}

resource "aws_route53_record" "cdn_a" {
  count = local.enable_cdn && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.cdn_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.uploads[0].domain_name
    zone_id                = aws_cloudfront_distribution.uploads[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cdn_aaaa" {
  count = local.enable_cdn && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.cdn_domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.uploads[0].domain_name
    zone_id                = aws_cloudfront_distribution.uploads[0].hosted_zone_id
    evaluate_target_health = false
  }
}

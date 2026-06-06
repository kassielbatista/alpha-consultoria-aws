output "bucket_name" {
  description = "S3 bucket name for uploads"
  value       = aws_s3_bucket.uploads.id
}

output "bucket_arn" {
  description = "S3 bucket ARN for uploads"
  value       = aws_s3_bucket.uploads.arn
}

output "api_role_arn" {
  description = "IAM role ARN for the API IRSA service account"
  value       = aws_iam_role.api.arn
}

output "api_role_name" {
  description = "IAM role name for the API IRSA service account"
  value       = aws_iam_role.api.name
}

output "cdn_domain_name" {
  description = "Custom CDN domain (null when CloudFront is disabled)"
  value       = local.enable_cdn ? var.cdn_domain_name : null
}

output "cdn_url" {
  description = "Public HTTPS base URL for uploaded media via CloudFront"
  value       = local.enable_cdn ? "https://${var.cdn_domain_name}" : null
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (null when disabled)"
  value       = local.enable_cdn ? aws_cloudfront_distribution.uploads[0].id : null
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain (null when disabled)"
  value       = local.enable_cdn ? aws_cloudfront_distribution.uploads[0].domain_name : null
}

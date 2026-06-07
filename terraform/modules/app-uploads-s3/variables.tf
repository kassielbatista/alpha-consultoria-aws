variable "bucket_name" {
  description = "S3 bucket name for application uploads"
  type        = string
}

variable "role_name" {
  description = "IAM role name for the API service account (IRSA)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL host (without https://)"
  type        = string
}

variable "service_account_namespace" {
  description = "Kubernetes namespace for the API service account"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name for the API"
  type        = string
}

variable "cdn_domain_name" {
  description = "Custom domain for the CloudFront distribution (e.g. cdn.example.com). Leave empty to skip CloudFront."
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the CDN domain (must be in us-east-1 for CloudFront)"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for the CDN alias record"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to created resources"
  type        = map(string)
  default     = {}
}

variable "enable_ses" {
  description = "Attach SES SendEmail permissions to the API IRSA role"
  type        = bool
  default     = false
}

variable "ses_domain_name" {
  description = "Verified SES domain for SendEmail permissions (e.g. example.com)"
  type        = string
  default     = ""
}

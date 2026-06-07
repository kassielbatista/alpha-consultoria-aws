output "domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.main.arn
}

output "domain_verification_token" {
  description = "SES domain verification token (also set automatically via Route53 DKIM)"
  value       = aws_ses_domain_identity.main.verification_token
}

output "mail_from_domain" {
  description = "Custom MAIL FROM subdomain configured for SPF/DMARC alignment"
  value       = aws_ses_domain_mail_from.main.mail_from_domain
}

# DNS Module Outputs

output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "domain_name" {
  description = "Domain name of the hosted zone"
  value       = aws_route53_zone.main.name
}

output "name_servers" {
  description = "Name servers to configure at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ARN of the ACM certificate (null if not created)"
  value       = var.create_certificate ? aws_acm_certificate.main[0].arn : null
}

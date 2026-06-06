# DNS Module
# Public Route53 hosted zone + (optional) ACM certificate validated via DNS.
#
# Flow:
#   1. terraform apply creates the zone and prints its name servers (outputs).
#   2. Point your registrar's NS records at those name servers.
#   3. Once DNS propagates, the ACM certificate validates automatically because
#      the validation CNAME records live inside this zone.
#   4. Set wait_for_validation = true on a later apply if you want Terraform to
#      block until the certificate is ISSUED (e.g. before wiring TLS into Ingress).

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform - ${var.domain_name}"

  tags = merge(var.tags, {
    Name = var.domain_name
  })
}

resource "aws_acm_certificate" "main" {
  count = var.create_certificate ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = var.domain_name
  })
}

# DNS validation records for the certificate (created inside the zone we manage)
resource "aws_route53_record" "cert_validation" {
  for_each = var.create_certificate ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Optional blocking validation. Disabled by default so the first apply (before the
# registrar NS delegation exists) does not hang waiting for DNS propagation.
resource "aws_acm_certificate_validation" "main" {
  count = var.create_certificate && var.wait_for_validation ? 1 : 0

  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

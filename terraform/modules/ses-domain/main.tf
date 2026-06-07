resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# Custom MAIL FROM aligns the envelope sender (Return-Path) with the From domain for DMARC/SPF.
resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = "${var.mail_from_subdomain}.${var.domain_name}"
}

resource "aws_route53_record" "mail_from_mx" {
  zone_id = var.route53_zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${var.region}.amazonses.com"]
}

resource "aws_route53_record" "mail_from_spf" {
  zone_id = var.route53_zone_id
  name    = aws_ses_domain_mail_from.main.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# SES always issues exactly 3 DKIM tokens; hardcode count to avoid plan-time unknown.
resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = var.route53_zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# SPF: add to the apex TXT record set alongside any existing values (e.g. Google
# site verification). Example value: v=spf1 include:amazonses.com ~all

locals {
  dmarc_rua = var.dmarc_report_email != "" ? "; rua=mailto:${var.dmarc_report_email}" : ""
  dmarc_txt = "v=DMARC1; p=${var.dmarc_policy}${local.dmarc_rua}; adkim=r; aspf=r; pct=100"
}

# DMARC — required for SES identity health (aligns SPF + DKIM under one policy).
resource "aws_route53_record" "dmarc" {
  zone_id = var.route53_zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = [local.dmarc_txt]
}

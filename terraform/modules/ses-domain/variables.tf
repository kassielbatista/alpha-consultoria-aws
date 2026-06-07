variable "domain_name" {
  description = "Domain to verify with SES"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DKIM and SPF records"
  type        = string
}

variable "region" {
  description = "AWS region where SES sends mail (for feedback-smtp MX target)"
  type        = string
  default     = "us-east-1"
}

variable "mail_from_subdomain" {
  description = "Subdomain for custom MAIL FROM (envelope sender), e.g. mail → mail.example.com"
  type        = string
  default     = "mail"
}

variable "dmarc_policy" {
  description = "DMARC policy (p=): none (monitor), quarantine, or reject"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "dmarc_policy must be none, quarantine, or reject."
  }
}

variable "dmarc_report_email" {
  description = "Optional inbox for DMARC aggregate reports (rua=mailto:...)"
  type        = string
  default     = ""
}

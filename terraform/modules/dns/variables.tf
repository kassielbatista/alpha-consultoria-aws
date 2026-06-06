# DNS Module Variables

variable "domain_name" {
  description = "Root domain for the hosted zone (e.g. roulettemanager.com.br)"
  type        = string
}

variable "subject_alternative_names" {
  description = "Extra names to include in the ACM certificate (wildcard recommended)"
  type        = list(string)
  default     = []
}

variable "create_certificate" {
  description = "Whether to request an ACM certificate for the domain"
  type        = bool
  default     = true
}

variable "wait_for_validation" {
  description = "Block until the ACM certificate is validated. Keep false until the registrar points NS at this zone, otherwise apply will hang."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Extra tags to apply to DNS resources"
  type        = map(string)
  default     = {}
}

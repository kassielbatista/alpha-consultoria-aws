# ECR Module Variables

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of tagged images to keep"
  type        = number
  default     = 30
}

variable "untagged_image_expiry_days" {
  description = "Number of days after which untagged images expire"
  type        = number
  default     = 7
}

variable "allow_pull_from_accounts" {
  description = "List of AWS account IDs allowed to pull images (optional)"
  type        = list(string)
  default     = null
}

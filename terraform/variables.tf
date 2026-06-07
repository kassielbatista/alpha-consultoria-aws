# Root Module Variables

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (used as a prefix for all resources)"
  type        = string
  default     = "alpha-k"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  default     = "prod"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cost savings vs HA)"
  type        = bool
  default     = true
}

# EKS Configuration
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

# ECR Configuration
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "alpha-k-app"
}

variable "analyzer_ecr_repositories" {
  description = "ECR repositories for the roulette-analyzer service images"
  type        = list(string)
  default = [
    "roulette-analyzer/backend",
    "roulette-analyzer/frontend",
    "roulette-analyzer/landing",
  ]
}

# Karpenter Configuration
variable "enable_karpenter" {
  description = "Provision Karpenter IAM/SQS resources for just-in-time node autoscaling"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "alert_email" {
  description = "Email address for alarm notifications (optional)"
  type        = string
  default     = ""
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarm (%)"
  type        = number
  default     = 70
}

variable "memory_alarm_threshold" {
  description = "Memory utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = true
}

# DNS Configuration
variable "domain_name" {
  description = "Root domain to manage in Route53 (set to enable the DNS module, e.g. roulettemanager.com.br)"
  type        = string
  default     = ""
}

variable "create_certificate" {
  description = "Request an ACM certificate (domain + wildcard) for the managed domain"
  type        = bool
  default     = true
}

variable "wait_for_cert_validation" {
  description = "Block apply until the ACM cert validates. Keep false until the registrar NS records point at this zone."
  type        = bool
  default     = false
}

# GitHub OIDC Configuration
variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name (set to enable GitHub Actions OIDC)"
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Noir Encontros app (second tenant on the shared alpha-k-eks cluster)
# ---------------------------------------------------------------------------

variable "noir_domain_name" {
  description = "Root domain for the noir-encontros app (set to enable its DNS module)"
  type        = string
  default     = ""
}

variable "noir_ecr_repositories" {
  description = "ECR repositories for the noir-encontros service images"
  type        = list(string)
  default = [
    "noir-encontros/api",
    "noir-encontros/web",
  ]
}

variable "noir_github_org" {
  description = "GitHub organization or username for the noir-encontros repo"
  type        = string
  default     = ""
}

variable "noir_github_repo" {
  description = "GitHub repository name for noir-encontros (set to enable its GitHub Actions OIDC role)"
  type        = string
  default     = ""
}

variable "noir_google_site_verification" {
  description = "Google Search Console domain verification TXT value (e.g. google-site-verification=...)"
  type        = string
  default     = ""
}

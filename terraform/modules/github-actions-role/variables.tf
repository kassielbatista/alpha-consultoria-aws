# GitHub Actions Role Module Variables
# A lean CI/CD role (build + push to ECR, deploy via Helm to EKS) that REUSES an
# existing GitHub OIDC provider. Use this for additional apps once the provider
# has already been created by the github-oidc module.

variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (repo:org/repo:*)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the existing GitHub OIDC provider"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_names" {
  description = "ECR repositories this role may push to"
  type        = list(string)
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster to grant deploy access to"
  type        = string
  default     = ""
}

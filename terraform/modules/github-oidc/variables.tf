# GitHub OIDC Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "enable_terraform_permissions" {
  description = "Enable full Terraform infrastructure permissions (for terraform-apply workflow)"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster to grant access to"
  type        = string
  default     = ""
}

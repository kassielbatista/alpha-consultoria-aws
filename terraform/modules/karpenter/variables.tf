# Karpenter Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster IRSA OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL (host/path) of the cluster IRSA OIDC provider, without https://"
  type        = string
}

variable "karpenter_namespace" {
  description = "Namespace where the Karpenter controller runs"
  type        = string
  default     = "kube-system"
}

variable "karpenter_service_account" {
  description = "ServiceAccount name used by the Karpenter controller"
  type        = string
  default     = "karpenter"
}

variable "node_security_group_ids" {
  description = "Security group IDs to tag for Karpenter node discovery"
  type        = list(string)
}

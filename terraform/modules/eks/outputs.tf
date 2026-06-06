# EKS Module Outputs

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_primary_security_group_id" {
  description = "EKS-managed primary cluster security group (used by nodes)"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.main.arn
}

output "node_role_arn" {
  description = "ARN of the IAM role for nodes"
  value       = aws_iam_role.node.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = local.oidc_provider_url
}

output "lb_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.lb_controller.arn
}

output "external_dns_role_arn" {
  description = "ARN of the IAM role for external-dns"
  value       = aws_iam_role.external_dns.arn
}

output "cluster_version" {
  description = "Version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

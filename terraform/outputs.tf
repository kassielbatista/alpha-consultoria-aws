# Root Module Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "analyzer_ecr_repository_urls" {
  description = "URLs of the roulette-analyzer ECR repositories keyed by repo name"
  value       = { for k, m in module.ecr_analyzer : k => m.repository_url }
}

# EKS Outputs
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "lb_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = module.eks.lb_controller_role_arn
}

output "external_dns_role_arn" {
  description = "ARN of the IAM role for external-dns"
  value       = module.eks.external_dns_role_arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = module.eks.oidc_provider_arn
}

# Monitoring Outputs
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.monitoring.sns_topic_arn
}

# Kubectl configuration command
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

# GitHub Actions Outputs
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions (set as AWS_ROLE_ARN secret)"
  value       = var.github_repo != "" ? module.github_oidc[0].role_arn : null
}

# Karpenter Outputs
output "karpenter_controller_role_arn" {
  description = "IAM role ARN for the Karpenter controller service account"
  value       = var.enable_karpenter ? module.karpenter[0].controller_role_arn : null
}

output "karpenter_node_role_name" {
  description = "IAM role name for Karpenter-launched nodes (used in EC2NodeClass)"
  value       = var.enable_karpenter ? module.karpenter[0].node_role_name : null
}

output "karpenter_interruption_queue" {
  description = "Name of the Karpenter SQS interruption queue"
  value       = var.enable_karpenter ? module.karpenter[0].interruption_queue_name : null
}

# DNS Outputs
output "domain_name_servers" {
  description = "Name servers for the managed hosted zone - add these as NS records at your registrar"
  value       = var.domain_name != "" ? module.dns[0].name_servers : []
}

output "domain_zone_id" {
  description = "Route53 hosted zone ID for the managed domain"
  value       = var.domain_name != "" ? module.dns[0].zone_id : null
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the managed domain (use in the Ingress)"
  value       = var.domain_name != "" ? module.dns[0].certificate_arn : null
}

# Noir Encontros Outputs
output "noir_domain_name_servers" {
  description = "Name servers for noirencontros.com.br - add these as NS records at your registrar"
  value       = var.noir_domain_name != "" ? module.dns_noir[0].name_servers : []
}

output "noir_domain_zone_id" {
  description = "Route53 hosted zone ID for noirencontros.com.br"
  value       = var.noir_domain_name != "" ? module.dns_noir[0].zone_id : null
}

output "noir_acm_certificate_arn" {
  description = "ARN of the ACM certificate for noirencontros.com.br (use in the Ingress)"
  value       = var.noir_domain_name != "" ? module.dns_noir[0].certificate_arn : null
}

output "noir_ecr_repository_urls" {
  description = "URLs of the noir-encontros ECR repositories keyed by repo name"
  value       = { for k, m in module.ecr_noir : k => m.repository_url }
}

output "noir_github_actions_role_arn" {
  description = "ARN of the IAM role for the noir-encontros GitHub Actions (set as AWS_ROLE_ARN secret)"
  value       = var.noir_github_repo != "" && var.github_repo != "" ? module.github_oidc_noir[0].role_arn : null
}

output "noir_uploads_bucket_name" {
  description = "S3 bucket for noir-encontros media uploads"
  value       = var.noir_domain_name != "" ? module.noir_uploads[0].bucket_name : null
}

output "noir_api_irsa_role_arn" {
  description = "IRSA role ARN for the noir-encontros API (set as NOIR_API_IRSA_ROLE_ARN secret and Helm api.serviceAccount.roleArn)"
  value       = var.noir_domain_name != "" ? module.noir_uploads[0].api_role_arn : null
}

output "noir_ses_domain_identity_arn" {
  description = "SES domain identity ARN for noirencontros.com.br"
  value       = var.noir_domain_name != "" ? module.ses_noir[0].domain_identity_arn : null
}

output "noir_uploads_cdn_url" {
  description = "CloudFront CDN base URL for noir-encontros media (use as NEXT_PUBLIC_UPLOAD_URL in web build)"
  value       = var.noir_domain_name != "" ? module.noir_uploads[0].cdn_url : null
}

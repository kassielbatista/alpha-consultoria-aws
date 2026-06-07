# Main Terraform Configuration
# Orchestrates all modules to create the complete infrastructure

locals {
  cluster_name = "${var.project_name}-eks"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name               = var.project_name
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
  cluster_name       = local.cluster_name

  # Let Karpenter discover private subnets via this tag (set declaratively here
  # so the subnet resource owns it - an out-of-band aws_ec2_tag would be stripped).
  private_subnet_tags = var.enable_karpenter ? { "karpenter.sh/discovery" = local.cluster_name } : {}
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
  scan_on_push    = true
  max_image_count = 30
}

# ECR repositories for the roulette-analyzer images (backend, frontend, landing)
module "ecr_analyzer" {
  source   = "./modules/ecr"
  for_each = toset(var.analyzer_ecr_repositories)

  repository_name = each.value
  scan_on_push    = true
  max_image_count = 20
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name        = local.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  environment         = var.environment
}

# Karpenter Module (just-in-time node autoscaling)
module "karpenter" {
  source = "./modules/karpenter"
  count  = var.enable_karpenter ? 1 : 0

  cluster_name            = module.eks.cluster_name
  oidc_provider_arn       = module.eks.oidc_provider_arn
  oidc_provider_url       = module.eks.oidc_provider_url
  node_security_group_ids = [module.eks.cluster_primary_security_group_id]

  depends_on = [module.eks]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name     = local.cluster_name
  environment      = var.environment
  region           = var.region
  alert_email      = var.alert_email
  cpu_threshold    = var.cpu_alarm_threshold
  memory_threshold = var.memory_alarm_threshold
  create_dashboard = var.create_dashboard

  depends_on = [module.eks]
}

# DNS Module (Route53 hosted zone + ACM certificate)
module "dns" {
  source = "./modules/dns"
  count  = var.domain_name != "" ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  create_certificate        = var.create_certificate
  wait_for_validation       = var.wait_for_cert_validation
}

# GitHub OIDC Module (for CI/CD)
module "github_oidc" {
  source = "./modules/github-oidc"
  count  = var.github_repo != "" ? 1 : 0

  project_name                 = var.project_name
  github_org                   = var.github_org
  github_repo                  = var.github_repo
  region                       = var.region
  ecr_repository_name          = var.ecr_repository_name
  enable_terraform_permissions = true
  eks_cluster_name             = module.eks.cluster_name

  depends_on = [module.eks]
}

# ---------------------------------------------------------------------------
# Noir Encontros app resources (shares the cluster, OIDC provider & external-dns)
# ---------------------------------------------------------------------------

# DNS - Route53 hosted zone + ACM certificate for noirencontros.com.br
module "dns_noir" {
  source = "./modules/dns"
  count  = var.noir_domain_name != "" ? 1 : 0

  domain_name               = var.noir_domain_name
  subject_alternative_names = ["*.${var.noir_domain_name}"]
  create_certificate        = var.create_certificate
  wait_for_validation       = var.wait_for_cert_validation
}

# Apex TXT: SPF for SES + optional Google Search Console verification.
resource "aws_route53_record" "noir_apex_txt" {
  count = var.noir_domain_name != "" ? 1 : 0

  zone_id = module.dns_noir[0].zone_id
  name    = var.noir_domain_name
  type    = "TXT"
  ttl     = 300
  records = compact([
    "v=spf1 include:amazonses.com ~all",
    var.noir_google_site_verification != "" ? var.noir_google_site_verification : null,
  ])
  allow_overwrite = true
}

# ECR repositories for the noir-encontros images (api, web)
module "ecr_noir" {
  source   = "./modules/ecr"
  for_each = toset(var.noir_ecr_repositories)

  repository_name = each.value
  scan_on_push    = true
  max_image_count = 20
}

# GitHub Actions role for the noir-encontros repo (reuses the shared OIDC provider)
module "github_oidc_noir" {
  source = "./modules/github-actions-role"
  count  = var.noir_github_repo != "" && var.github_repo != "" ? 1 : 0

  role_name            = "noir-encontros-github-actions-role"
  github_org           = var.noir_github_org
  github_repo          = var.noir_github_repo
  oidc_provider_arn    = module.github_oidc[0].oidc_provider_arn
  region               = var.region
  ecr_repository_names = var.noir_ecr_repositories
  eks_cluster_name     = module.eks.cluster_name

  depends_on = [module.eks, module.github_oidc]
}

# SES domain identity + DKIM/SPF for transactional email
module "ses_noir" {
  source = "./modules/ses-domain"
  count  = var.noir_domain_name != "" ? 1 : 0

  domain_name     = var.noir_domain_name
  route53_zone_id = module.dns_noir[0].zone_id
  region          = var.region

  depends_on = [module.dns_noir]
}

# S3 uploads bucket + IRSA for the noir-encontros API pods
module "noir_uploads" {
  source = "./modules/app-uploads-s3"
  count  = var.noir_domain_name != "" ? 1 : 0

  bucket_name               = "${var.project_name}-noir-encontros-uploads"
  role_name                 = "${module.eks.cluster_name}-noir-encontros-api-role"
  oidc_provider_arn         = module.eks.oidc_provider_arn
  oidc_provider_url         = module.eks.oidc_provider_url
  service_account_namespace = "noir-encontros"
  service_account_name      = "noir-encontros-api"
  cdn_domain_name           = "cdn.${var.noir_domain_name}"
  acm_certificate_arn       = module.dns_noir[0].certificate_arn
  route53_zone_id           = module.dns_noir[0].zone_id
  enable_ses      = true
  ses_domain_name = var.noir_domain_name

  tags = {
    Application = "noir-encontros"
  }

  depends_on = [module.eks, module.dns_noir]
}

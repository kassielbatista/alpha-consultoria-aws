# GitHub Actions Role Module
# Creates an IAM role assumable by a single GitHub repo via the shared OIDC
# provider. Scoped to ECR push + EKS deploy only (no Terraform/state perms).

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = var.role_name
  }
}

# ECR - push/pull images for this app's repositories
resource "aws_iam_role_policy" "ecr" {
  name = "${var.role_name}-ecr"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = [
          for name in var.ecr_repository_names :
          "arn:${data.aws_partition.current.partition}:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${name}"
        ]
      }
    ]
  })
}

# EKS - describe clusters so the workflow can fetch kubeconfig
resource "aws_iam_role_policy" "eks" {
  name = "${var.role_name}-eks"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster", "eks:ListClusters"]
        Resource = "*"
      }
    ]
  })
}

# EKS access entry - lets this role run kubectl/helm against the cluster
resource "aws_eks_access_entry" "this" {
  count         = var.eks_cluster_name != "" ? 1 : 0
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.this.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  count         = var.eks_cluster_name != "" ? 1 : 0
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.this.arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.this]
}

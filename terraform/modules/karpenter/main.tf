# Karpenter Module
# Provisions the AWS-side resources Karpenter needs:
#   - IAM role for nodes Karpenter launches (+ EKS access entry so they can join)
#   - IAM role for the Karpenter controller (IRSA)
#   - SQS interruption queue + EventBridge rules (spot/rebalance/health events)
#   - karpenter.sh/discovery tags on subnets and node security groups

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

############################################
# Node IAM role (instances Karpenter launches)
############################################
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = { Name = "${var.cluster_name}-karpenter-node-role" }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

# Let Karpenter-launched nodes register with the cluster.
resource "aws_eks_access_entry" "node" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.node.arn
  type          = "EC2_LINUX"
}

############################################
# Controller IAM role (IRSA)
############################################
resource "aws_iam_role" "controller" {
  name = "${var.cluster_name}-karpenter-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = var.oidc_provider_arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.karpenter_namespace}:${var.karpenter_service_account}"
          }
        }
      }
    ]
  })

  tags = { Name = "${var.cluster_name}-karpenter-controller-role" }
}

resource "aws_iam_role_policy" "controller" {
  name = "${var.cluster_name}-karpenter-controller-policy"
  role = aws_iam_role.controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Provisioning"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "ec2:Describe*",
          "ec2:GetSpotPlacementScores"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowSSMReadActions"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:${local.partition}:ssm:${local.region}::parameter/aws/service/*"
      },
      {
        Sid      = "AllowPricingReadActions"
        Effect   = "Allow"
        Action   = ["pricing:GetProducts"]
        Resource = "*"
      },
      {
        Sid    = "AllowInterruptionQueueActions"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.interruption.arn
      },
      {
        Sid      = "AllowPassingInstanceRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = aws_iam_role.node.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowInstanceProfileActions"
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowAPIServerEndpointDiscovery"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "arn:${local.partition}:eks:${local.region}:${local.account_id}:cluster/${var.cluster_name}"
      }
    ]
  })
}

############################################
# Interruption handling (SQS + EventBridge)
############################################
resource "aws_sqs_queue" "interruption" {
  name                      = "${var.cluster_name}-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true

  tags = { Name = "${var.cluster_name}-karpenter" }
}

resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EventBridgeToQueue"
        Effect    = "Allow"
        Principal = { Service = ["events.amazonaws.com", "sqs.amazonaws.com"] }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.interruption.arn
      }
    ]
  })
}

locals {
  event_rules = {
    spot_interruption = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Spot Instance Interruption Warning"]
    }
    rebalance = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Instance Rebalance Recommendation"]
    }
    instance_state_change = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Instance State-change Notification"]
    }
    scheduled_change = {
      source      = ["aws.health"]
      detail_type = ["AWS Health Event"]
    }
  }
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.event_rules

  name          = "${var.cluster_name}-karpenter-${each.key}"
  event_pattern = jsonencode({ "source" = each.value.source, "detail-type" = each.value.detail_type })

  tags = { Name = "${var.cluster_name}-karpenter-${each.key}" }
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.event_rules

  rule      = aws_cloudwatch_event_rule.this[each.key].name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.interruption.arn
}

############################################
# Discovery tags for security groups
# (private subnets are tagged declaratively in the VPC module to avoid the
#  aws_ec2_tag <-> aws_subnet tag-ownership conflict.)
############################################
resource "aws_ec2_tag" "sg_discovery" {
  for_each    = toset(var.node_security_group_ids)
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

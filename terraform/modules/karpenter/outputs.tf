# Karpenter Module Outputs

output "controller_role_arn" {
  description = "IAM role ARN for the Karpenter controller (annotate the service account)"
  value       = aws_iam_role.controller.arn
}

output "node_role_name" {
  description = "IAM role name for Karpenter-launched nodes (used in EC2NodeClass)"
  value       = aws_iam_role.node.name
}

output "node_role_arn" {
  description = "IAM role ARN for Karpenter-launched nodes"
  value       = aws_iam_role.node.arn
}

output "interruption_queue_name" {
  description = "Name of the SQS interruption queue"
  value       = aws_sqs_queue.interruption.name
}

# Monitoring Module Outputs

output "app_log_group_name" {
  description = "Name of the application log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "app_log_group_arn" {
  description = "ARN of the application log group"
  value       = aws_cloudwatch_log_group.app.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = var.create_sns_topic ? aws_sns_topic.alerts[0].arn : null
}

output "cpu_alarm_arn" {
  description = "ARN of the CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.node_cpu_high.arn
}

output "memory_alarm_arn" {
  description = "ARN of the memory utilization alarm"
  value       = aws_cloudwatch_metric_alarm.node_memory_high.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

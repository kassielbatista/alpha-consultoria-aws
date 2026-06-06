# Monitoring Module
# Creates CloudWatch alarms, log groups, and optional dashboard

# Log group for application logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/eks/${var.cluster_name}/app"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.cluster_name}-app-logs"
    Environment = var.environment
  }
}

# SNS Topic for alarms (optional)
resource "aws_sns_topic" "alerts" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.cluster_name}-alerts"

  tags = {
    Name        = "${var.cluster_name}-alerts"
    Environment = var.environment
  }
}

# SNS Topic subscription (email)
resource "aws_sns_topic_subscription" "email" {
  count     = var.create_sns_topic && var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CPU Utilization Alarm for EKS Nodes
resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${var.cluster_name}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "EKS node CPU utilization is above ${var.cpu_threshold}%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions    = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []

  tags = {
    Name        = "${var.cluster_name}-node-cpu-high"
    Environment = var.environment
  }
}

# Memory Utilization Alarm for EKS Nodes
resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  alarm_name          = "${var.cluster_name}-node-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "EKS node memory utilization is above ${var.memory_threshold}%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []
  ok_actions    = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []

  tags = {
    Name        = "${var.cluster_name}-node-memory-high"
    Environment = var.environment
  }
}

# Pod restart alarm
resource "aws_cloudwatch_metric_alarm" "pod_restarts" {
  alarm_name          = "${var.cluster_name}-pod-restarts-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "High number of pod restarts detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = var.create_sns_topic ? [aws_sns_topic.alerts[0].arn] : []

  tags = {
    Name        = "${var.cluster_name}-pod-restarts-high"
    Environment = var.environment
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${var.cluster_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Node CPU Utilization"
          region = var.region
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", var.cluster_name, { stat = "Average" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Node Memory Utilization"
          region = var.region
          metrics = [
            ["ContainerInsights", "node_memory_utilization", "ClusterName", var.cluster_name, { stat = "Average" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Pod Count"
          region = var.region
          metrics = [
            ["ContainerInsights", "pod_number_of_running_containers", "ClusterName", var.cluster_name, { stat = "Average" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Network (Bytes)"
          region = var.region
          metrics = [
            ["ContainerInsights", "node_network_total_bytes", "ClusterName", var.cluster_name, { stat = "Average" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      }
    ]
  })
}

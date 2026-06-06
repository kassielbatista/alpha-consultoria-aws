# Monitoring Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "create_sns_topic" {
  description = "Create SNS topic for alarm notifications"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for alarm (%)"
  type        = number
  default     = 70
}

variable "memory_threshold" {
  description = "Memory utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate for alarm"
  type        = number
  default     = 2
}

variable "alarm_period" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300
}

variable "create_dashboard" {
  description = "Create CloudWatch dashboard"
  type        = bool
  default     = true
}

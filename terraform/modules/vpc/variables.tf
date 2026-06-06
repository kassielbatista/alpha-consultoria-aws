# VPC Module Variables

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets (cost savings vs HA)"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster (for subnet tagging)"
  type        = string
}

variable "private_subnet_tags" {
  description = "Extra tags to apply to private subnets (e.g. karpenter.sh/discovery)"
  type        = map(string)
  default     = {}
}

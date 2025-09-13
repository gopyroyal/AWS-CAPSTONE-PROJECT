variable "project_prefix" {
  description = "Naming prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name: dev, staging, prod"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "allowed_http_cidr" {
  description = "CIDR for ingress to ALB (default open)"
  type        = string
  default     = "0.0.0.0/0"
}

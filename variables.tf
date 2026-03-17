# Simplified variables for AWS Academy
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_ssl_enabled" {
  description = "Enable SSL for database"
  type        = string
  default     = "true"
}

# Missing variables for OpenAPI template
variable "alb_endpoint" {
  description = "ALB endpoint URL"
  type        = string
  default     = ""
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 10000
}

# AWS Academy specific variables
variable "lab_role" {
  description = "ARN of the LabRole"
  type        = string
  default     = ""
}

variable "lambda_subnet_ids" {
  description = "Lambda subnet IDs"
  type        = list(string)
  default     = null
}

variable "lambda_security_group_ids" {
  description = "Lambda security group IDs"
  type        = list(string)
  default     = null
}
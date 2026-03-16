variable "aws_region" {
  description = "AWS region for API Gateway deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

variable "alb_endpoint" {
  description = "Application Load Balancer endpoint URL (backend service)"
  type        = string
}

variable "jwt_secret" {
  description = "JWT secret key for token validation (must match backend)"
  type        = string
  sensitive   = true
}

variable "allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 10000
}

variable "enable_waf" {
  description = "Enable AWS WAF for API Gateway"
  type        = bool
  default     = false
}

variable "enable_api_key" {
  description = "Enable API key requirement for endpoints"
  type        = bool
  default     = false
}

# Database configuration for Lambda authentication
# Note: db_host, db_port, db_name, and db_user are read from remote state
# Only db_password needs to be provided as it's sensitive
variable "db_password" {
  description = "PostgreSQL database password (must match the backend infrastructure)"
  type        = string
  sensitive   = true
}

variable "db_ssl_enabled" {
  description = "Enable SSL for database connection"
  type        = string
  default     = "true"
}

# AWS Academy IAM Configuration
variable "lab_role" {
  description = "ARN of the LabRole (leave empty to auto-construct)"
  type        = string
  default     = ""
}

variable "principal_arn" {
  description = "ARN of the principal role (leave empty to auto-construct)"
  type        = string
  default     = ""
}

# VPC configuration for Lambda
# Note: lambda_subnet_ids and lambda_security_group_ids are read from remote state
# These variables are kept for override capability if needed
variable "lambda_subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration (optional, defaults to remote state)"
  type        = list(string)
  default     = null
}

variable "lambda_security_group_ids" {
  description = "List of security group IDs for Lambda (optional, defaults to remote state)"
  type        = list(string)
  default     = null
}

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
variable "db_host" {
  description = "PostgreSQL database host (RDS endpoint)"
  type        = string
}

variable "db_port" {
  description = "PostgreSQL database port"
  type        = string
  default     = "5432"
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "oficina_tech_db"
}

variable "db_ssl_enabled" {
  description = "Enable SSL for database connection"
  type        = string
  default     = "true"
}

# VPC configuration for Lambda
variable "lambda_subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration (must have access to RDS)"
  type        = list(string)
}

variable "lambda_security_group_ids" {
  description = "List of security group IDs for Lambda (must allow outbound to RDS)"
  type        = list(string)
}

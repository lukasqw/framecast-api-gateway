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

# ─── Terraform State ──────────────────────────────────────────────────────────
variable "tf_state_bucket" {
  description = "Bucket S3 para state do Terraform. Configure TF_STATE_BUCKET nas variáveis do repositório no GitHub Actions. Default mantido para compatibilidade local."
  type        = string
  default     = "fiap-soat-tf-backend-bispo-730335587750"
}

# Legacy single-backend override (kept for compatibility — prefer the per-MS variables below)
variable "alb_endpoint" {
  description = "NLB endpoint URL override (deprecated — use ms_*_endpoint instead)"
  type        = string
  default     = ""
}

# Per-microservice endpoint overrides (optional — auto-detected from NLB remote state + NodePort)
variable "ms_identity_endpoint" {
  description = "ms-identity endpoint URL override (default: nlb_dns:30081)"
  type        = string
  default     = ""
}

variable "ms_order_endpoint" {
  description = "ms-order-service endpoint URL override (default: nlb_dns:30082)"
  type        = string
  default     = ""
}

variable "ms_workshop_endpoint" {
  description = "ms-workshop endpoint URL override (default: nlb_dns:30083)"
  type        = string
  default     = ""
}

# API Gateway Rate Limiting
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

variable "quota_limit" {
  description = "Daily quota limit for API requests"
  type        = number
  default     = 1000000
}

# Logging and Monitoring
variable "enable_logging" {
  description = "Enable CloudWatch logging for API Gateway"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms for API Gateway"
  type        = bool
  default     = false
}

variable "error_threshold_5xx" {
  description = "Threshold for 5XX errors alarm"
  type        = number
  default     = 10
}

variable "error_threshold_4xx" {
  description = "Threshold for 4XX errors alarm"
  type        = number
  default     = 100
}

variable "latency_threshold_ms" {
  description = "Threshold for latency alarm in milliseconds"
  type        = number
  default     = 5000
}

# API Key Configuration
variable "enable_api_key" {
  description = "Enable API Key authentication"
  type        = bool
  default     = false
}

# Custom Domain
variable "custom_domain_name" {
  description = "Custom domain name for API Gateway"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain"
  type        = string
  default     = ""
}

variable "base_path" {
  description = "Base path for API Gateway custom domain mapping"
  type        = string
  default     = ""
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

# Cache Configuration
variable "enable_cache" {
  description = "Enable API Gateway caching"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Cache cluster size (0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237)"
  type        = string
  default     = "0.5"
}

variable "cache_ttl_seconds" {
  description = "Cache TTL in seconds"
  type        = number
  default     = 300
}

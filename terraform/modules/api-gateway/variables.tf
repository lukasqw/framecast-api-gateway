# ============================================================================
# API Gateway Module Variables
# ============================================================================

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = ""
}

variable "openapi_spec" {
  description = "OpenAPI specification as string"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

variable "xray_tracing_enabled" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

# Logging
variable "enable_logging" {
  description = "Enable CloudWatch logging"
  type        = bool
  default     = false
}

variable "logging_level" {
  description = "Logging level (OFF, ERROR, INFO)"
  type        = string
  default     = "INFO"
}

variable "log_group_arn" {
  description = "CloudWatch Log Group ARN for access logs"
  type        = string
  default     = ""
}

# Cache
variable "enable_cache" {
  description = "Enable API Gateway caching"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Cache cluster size"
  type        = string
  default     = "0.5"
}

variable "cache_ttl_seconds" {
  description = "Cache TTL in seconds"
  type        = number
  default     = 300
}

# Rate Limiting
variable "throttle_burst_limit" {
  description = "Throttle burst limit"
  type        = number
  default     = 5000
}

variable "throttle_rate_limit" {
  description = "Throttle rate limit (requests per second)"
  type        = number
  default     = 10000
}

variable "quota_limit" {
  description = "Daily quota limit"
  type        = number
  default     = 1000000
}

# Usage Plan
variable "usage_plan_name" {
  description = "Name of the usage plan"
  type        = string
}

variable "usage_plan_description" {
  description = "Description of the usage plan"
  type        = string
  default     = ""
}

# API Key
variable "enable_api_key" {
  description = "Enable API Key"
  type        = bool
  default     = false
}

variable "api_key_name" {
  description = "Name of the API Key"
  type        = string
  default     = ""
}

# Custom Domain
variable "custom_domain_name" {
  description = "Custom domain name"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
  default     = ""
}

variable "base_path" {
  description = "Base path for custom domain"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

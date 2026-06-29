variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

# ── Terraform State ───────────────────────────────────────────────────────────

variable "tf_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "fiap-soat-tf-backend-framecast"
}

# ── Backend endpoint override ─────────────────────────────────────────────────

variable "framecast_api_endpoint" {
  description = "Override for framecast-api endpoint (host:port only, sem http://). Empty = derived from NLB DNS + nodeport."
  type        = string
  default     = ""
}

variable "nodeport" {
  description = "NLB listener port (80 → NodePort 30080 on EKS nodes)"
  type        = number
  default     = 80
}

# ── Feature flags ─────────────────────────────────────────────────────────────

variable "enable_vpc_link" {
  description = "Create VPC Link (INTERNET fallback when false — useful for LocalStack/dev)"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Attach WAFv2 WebACL to the stage (disable if LabRole lacks wafv2:* permissions)"
  type        = bool
  default     = true
}

# ── WAF ───────────────────────────────────────────────────────────────────────

variable "waf_rate_limit" {
  description = "WAF rate-based rule: max requests per 5 minutes per IP"
  type        = number
  default     = 2000
}

# ── API Gateway Rate Limiting ─────────────────────────────────────────────────

variable "throttle_burst_limit" {
  description = "API Gateway burst limit"
  type        = number
  default     = 5000
}

variable "throttle_rate_limit" {
  description = "API Gateway rate limit (req/s)"
  type        = number
  default     = 10000
}

variable "quota_limit" {
  description = "API Gateway daily quota"
  type        = number
  default     = 1000000
}

# ── Cache ─────────────────────────────────────────────────────────────────────

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

# ── Logging and Monitoring ────────────────────────────────────────────────────

variable "enable_logging" {
  description = "Enable CloudWatch access logging (requer apigateway:UpdateRestApiAccount — desabilitado no Academy LabRole)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "error_threshold_5xx" {
  description = "5XX error count threshold for alarm"
  type        = number
  default     = 10
}

variable "error_threshold_4xx" {
  description = "4XX error count threshold for alarm"
  type        = number
  default     = 100
}

variable "latency_threshold_ms" {
  description = "Latency threshold in milliseconds for alarm"
  type        = number
  default     = 5000
}

# ── API Key (optional) ────────────────────────────────────────────────────────

variable "enable_api_key" {
  description = "Enable API Key authentication"
  type        = bool
  default     = false
}

# ── Custom Domain (optional) ──────────────────────────────────────────────────

variable "custom_domain_name" {
  description = "Custom domain name (empty = disabled)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain"
  type        = string
  default     = ""
}

# ── AWS Academy ───────────────────────────────────────────────────────────────

variable "lab_role" {
  description = "LabRole ARN override (empty = auto-derive from caller account)"
  type        = string
  default     = ""
}

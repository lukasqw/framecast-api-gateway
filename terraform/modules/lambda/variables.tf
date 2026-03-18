# ============================================================================
# Lambda Module Variables
# ============================================================================

variable "filename" {
  description = "Path to the Lambda deployment package"
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "description" {
  description = "Lambda function description"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Environment variables for Lambda"
  type        = map(string)
  default     = {}
}

# VPC Configuration
variable "vpc_subnet_ids" {
  description = "VPC subnet IDs for Lambda"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs for Lambda"
  type        = list(string)
  default     = null
}

# API Gateway Permission
variable "create_api_gateway_permission" {
  description = "Create API Gateway invoke permission"
  type        = bool
  default     = true
}

variable "permission_statement_id" {
  description = "Statement ID for Lambda permission"
  type        = string
  default     = "AllowAPIGatewayInvoke"
}

variable "api_gateway_source_arn" {
  description = "API Gateway source ARN for Lambda permission"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

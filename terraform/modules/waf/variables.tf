variable "name" {
  description = "Name of the WAF WebACL"
  type        = string
}

variable "enabled" {
  description = "Create and attach the WAF WebACL (disable if LabRole lacks wafv2:* permissions)"
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "Max requests per 5 minutes per IP before blocking"
  type        = number
  default     = 2000
}

variable "resource_arn" {
  description = "ARN of the API Gateway stage to associate with the WebACL"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the WebACL"
  type        = map(string)
  default     = {}
}

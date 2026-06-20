variable "name" {
  description = "Name of the VPC Link"
  type        = string
}

variable "nlb_arn" {
  description = "ARN of the Network Load Balancer to attach"
  type        = string
}

variable "enabled" {
  description = "Create the VPC Link (false = skip, used in dev/LocalStack)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the VPC Link"
  type        = map(string)
  default     = {}
}

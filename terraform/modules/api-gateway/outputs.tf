# ============================================================================
# API Gateway Module Outputs
# ============================================================================

output "rest_api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_name" {
  description = "API Gateway REST API name"
  value       = aws_api_gateway_rest_api.this.name
}

output "rest_api_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "stage_name" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.this.stage_name
}

output "stage_invoke_url" {
  description = "API Gateway stage invoke URL"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "deployment_id" {
  description = "API Gateway deployment ID"
  value       = aws_api_gateway_deployment.this.id
}

output "usage_plan_id" {
  description = "Usage Plan ID"
  value       = aws_api_gateway_usage_plan.this.id
}

output "usage_plan_name" {
  description = "Usage Plan name"
  value       = aws_api_gateway_usage_plan.this.name
}

output "api_key_id" {
  description = "API Key ID (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.this[0].id : null
}

output "api_key_value" {
  description = "API Key value (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.this[0].value : null
  sensitive   = true
}

output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].domain_name : null
}

output "custom_domain_regional_domain_name" {
  description = "Regional domain name for custom domain"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].regional_domain_name : null
}

output "custom_domain_regional_zone_id" {
  description = "Regional zone ID for custom domain"
  value       = var.custom_domain_name != "" ? aws_api_gateway_domain_name.this[0].regional_zone_id : null
}

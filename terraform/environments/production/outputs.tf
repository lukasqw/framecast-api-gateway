# API Gateway Outputs
output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = module.api_gateway.rest_api_id
}

output "api_gateway_name" {
  description = "API Gateway REST API name"
  value       = module.api_gateway.rest_api_name
}

output "api_gateway_url" {
  description = "Base URL for API Gateway"
  value       = module.api_gateway.stage_invoke_url
}

output "api_gateway_stage" {
  description = "API Gateway stage name"
  value       = module.api_gateway.stage_name
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  value       = module.api_gateway.rest_api_execution_arn
}

# Lambda Outputs
output "cpf_auth_lambda_name" {
  description = "Nome da função Lambda de autenticação CPF"
  value       = module.lambda_auth.function_name
}

output "cpf_auth_lambda_arn" {
  description = "ARN da função Lambda de autenticação CPF"
  value       = module.lambda_auth.function_arn
}

# Usage Plan Outputs
output "usage_plan_id" {
  description = "API Gateway Usage Plan ID"
  value       = module.api_gateway.usage_plan_id
}

output "usage_plan_name" {
  description = "API Gateway Usage Plan Name"
  value       = module.api_gateway.usage_plan_name
}

# API Key Outputs
output "api_key_id" {
  description = "API Key ID (if enabled)"
  value       = module.api_gateway.api_key_id
}

output "api_key_value" {
  description = "API Key Value (if enabled)"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}

# Custom Domain Outputs
output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = module.api_gateway.custom_domain_name
}

output "custom_domain_regional_domain_name" {
  description = "Regional domain name for custom domain"
  value       = module.api_gateway.custom_domain_regional_domain_name
}

output "custom_domain_regional_zone_id" {
  description = "Regional zone ID for custom domain"
  value       = module.api_gateway.custom_domain_regional_zone_id
}

# CloudWatch Outputs
output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

# Endpoint Outputs
output "alb_endpoint_configured" {
  description = "ALB endpoint configurado no API Gateway"
  value       = local.alb_endpoint
}

output "alb_endpoint_source" {
  description = "Fonte do ALB endpoint (remote_state ou variable)"
  value       = var.alb_endpoint != "" ? "variable" : "remote_state"
}

output "db_host_configured" {
  description = "DB Host configurado no Lambda"
  value       = local.db_host
}

output "db_connection_string" {
  description = "String de conexão do banco (sem senha)"
  value       = "postgresql://${local.db_user}@${local.db_host}:${local.db_port}/${local.db_name}"
}

# Lambda VPC Configuration Outputs
output "lambda_security_groups" {
  description = "Security groups usados pelo Lambda"
  value       = local.lambda_security_group_ids
}

output "lambda_subnets" {
  description = "Subnets usadas pelo Lambda"
  value       = local.lambda_subnet_ids
}

# Test Commands
output "test_auth_command" {
  description = "Comando para testar autenticação"
  value       = "curl -X POST ${module.api_gateway.stage_invoke_url}/auth/login -H 'Content-Type: application/json' -d '{\"cpf\":\"12345678901\",\"password\":\"senha123\",\"type\":\"customer\"}'"
}

output "test_customers_command" {
  description = "Comando para testar listagem de clientes (requer token)"
  value       = "curl -X GET ${module.api_gateway.stage_invoke_url}/customers -H 'Authorization: Bearer YOUR_TOKEN_HERE'"
}

output "api_documentation_url" {
  description = "URL da documentação da API (OpenAPI/Swagger)"
  value       = "${module.api_gateway.stage_invoke_url}/swagger-ui"
}

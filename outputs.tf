output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.oficina_tech.id
}

output "api_gateway_url" {
  description = "Base URL for API Gateway"
  value       = aws_api_gateway_stage.oficina_tech.invoke_url
}

output "api_gateway_stage" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.oficina_tech.stage_name
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.oficina_tech.execution_arn
}

output "alb_endpoint_configured" {
  description = "ALB endpoint configurado no API Gateway"
  value       = local.alb_endpoint
}

output "alb_endpoint_source" {
  description = "Fonte do ALB endpoint (remote_state ou variable)"
  value       = var.alb_endpoint != "" ? "variable" : "remote_state"
}

output "api_gateway_endpoint" {
  description = "Full API Gateway endpoint URL"
  value       = aws_api_gateway_stage.oficina_tech.invoke_url
}

output "cpf_auth_lambda_name" {
  description = "Nome da função Lambda de autenticação CPF"
  value       = aws_lambda_function.cpf_auth.function_name
}

output "cpf_auth_lambda_arn" {
  description = "ARN da função Lambda de autenticação CPF"
  value       = aws_lambda_function.cpf_auth.arn
}

output "test_auth_command" {
  description = "Comando para testar autenticação"
  value       = "curl -X POST ${aws_api_gateway_stage.oficina_tech.invoke_url}/auth/login -H 'Content-Type: application/json' -d '{\"cpf\":\"12345678901\",\"password\":\"senha123\",\"type\":\"customer\"}'"
}

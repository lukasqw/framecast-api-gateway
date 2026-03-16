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

output "lambda_authorizer_arn" {
  description = "Lambda authorizer function ARN"
  value       = aws_lambda_function.jwt_authorizer.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

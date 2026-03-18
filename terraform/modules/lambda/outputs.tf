# ============================================================================
# Lambda Module Outputs
# ============================================================================

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

output "function_invoke_arn" {
  description = "Lambda function invoke ARN"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_qualified_arn" {
  description = "Lambda function qualified ARN"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_version" {
  description = "Lambda function version"
  value       = aws_lambda_function.this.version
}

output "function_last_modified" {
  description = "Lambda function last modified date"
  value       = aws_lambda_function.this.last_modified
}

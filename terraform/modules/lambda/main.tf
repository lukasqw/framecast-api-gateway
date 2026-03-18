# ============================================================================
# Lambda Module
# ============================================================================

resource "aws_lambda_function" "this" {
  filename         = var.filename
  function_name    = var.function_name
  role             = var.role_arn
  handler          = var.handler
  source_code_hash = filebase64sha256(var.filename)
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  description      = var.description

  environment {
    variables = var.environment_variables
  }

  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
  }
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  count = var.create_api_gateway_permission ? 1 : 0

  statement_id  = var.permission_statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_source_arn
}

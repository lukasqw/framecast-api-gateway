# Lambda function for JWT authorization
resource "aws_lambda_function" "jwt_authorizer" {
  filename         = "${path.module}/lambda/authorizer.zip"
  function_name    = "oficina-tech-jwt-authorizer-${var.environment}"
  role             = local.lambda_execution_role_arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/authorizer.zip")
  runtime          = "nodejs20.x"
  timeout          = 10

  environment {
    variables = {
      JWT_SECRET           = var.jwt_secret
      AWS_LAMBDA_LOG_LEVEL = "INFO"
    }
  }

  tags = {
    Name = "oficina-tech-jwt-authorizer"
  }

  # Força recriação quando o código muda
  lifecycle {
    replace_triggered_by = [
      null_resource.lambda_code_trigger
    ]
  }
}

# Permissão para API Gateway invocar a Lambda do Authorizer
resource "aws_lambda_permission" "api_gateway_authorizer" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jwt_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.oficina_tech.execution_arn}/*/*"

  depends_on = [
    aws_api_gateway_rest_api.oficina_tech
  ]
}

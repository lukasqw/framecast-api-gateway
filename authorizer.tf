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
      AWS_LAMBDA_LOG_LEVEL = "FATAL"
    }
  }

  tags = {
    Name = "oficina-tech-jwt-authorizer"
  }
}

# API Gateway Authorizer
resource "aws_api_gateway_authorizer" "jwt" {
  name                             = "oficina-tech-jwt-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.oficina_tech.id
  authorizer_uri                   = aws_lambda_function.jwt_authorizer.invoke_arn
  authorizer_credentials           = local.lambda_execution_role_arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}

# Lambda function for JWT authorization
resource "aws_lambda_function" "jwt_authorizer" {
  filename         = "${path.module}/lambda/authorizer.zip"
  function_name    = "oficina-tech-jwt-authorizer-${var.environment}"
  role             = var.use_lab_role ? local.lambda_execution_role_arn : aws_iam_role.lambda_authorizer[0].arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/authorizer.zip")
  runtime          = "nodejs20.x"
  timeout          = 10

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }

  tags = {
    Name = "oficina-tech-jwt-authorizer"
  }
}

# IAM Role for Lambda Authorizer
resource "aws_iam_role" "lambda_authorizer" {
  count = var.use_lab_role ? 0 : 1
  name  = "oficina-tech-lambda-authorizer-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_basic" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.lambda_authorizer[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_authorizer" {
  name              = "/aws/lambda/oficina-tech-jwt-authorizer-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "oficina-tech-lambda-authorizer-logs"
  }
}

# API Gateway Authorizer
resource "aws_api_gateway_authorizer" "jwt" {
  name                             = "oficina-tech-jwt-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.oficina_tech.id
  authorizer_uri                   = aws_lambda_function.jwt_authorizer.invoke_arn
  authorizer_credentials           = var.use_lab_role ? local.lambda_execution_role_arn : aws_iam_role.api_gateway_authorizer_invocation[0].arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}

# IAM Role for API Gateway to invoke Lambda
resource "aws_iam_role" "api_gateway_authorizer_invocation" {
  count = var.use_lab_role ? 0 : 1
  name  = "oficina-tech-api-gateway-auth-invocation-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_authorizer_invocation" {
  count = var.use_lab_role ? 0 : 1
  name  = "oficina-tech-lambda-invoke"
  role  = aws_iam_role.api_gateway_authorizer_invocation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.jwt_authorizer.arn
      }
    ]
  })
}

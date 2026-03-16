# Lambda function para autenticação via CPF
resource "aws_lambda_function" "cpf_auth" {
  filename         = "${path.module}/lambda/auth.zip"
  function_name    = "oficina-tech-cpf-auth-${var.environment}"
  role             = var.use_lab_role ? local.lambda_execution_role_arn : aws_iam_role.lambda_cpf_auth[0].arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/auth.zip")
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      JWT_SECRET           = var.jwt_secret
      DB_HOST              = local.db_host
      DB_PORT              = local.db_port
      DB_USER              = local.db_user
      DB_PASSWORD          = var.db_password
      DB_NAME              = local.db_name
      DB_SSL               = var.db_ssl_enabled
      AWS_LAMBDA_LOG_LEVEL = "FATAL"
    }
  }

  vpc_config {
    subnet_ids         = coalesce(var.lambda_subnet_ids, local.lambda_subnet_ids)
    security_group_ids = coalesce(var.lambda_security_group_ids, local.lambda_security_group_ids)
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/null"
  }

  tags = {
    Name = "oficina-tech-cpf-auth"
  }
}

# IAM Role para Lambda de Autenticação
resource "aws_iam_role" "lambda_cpf_auth" {
  count = var.use_lab_role ? 0 : 1
  name  = "oficina-tech-lambda-cpf-auth-${var.environment}"

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

# Políticas básicas para Lambda
resource "aws_iam_role_policy_attachment" "lambda_cpf_auth_basic" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.lambda_cpf_auth[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Política para acesso VPC (necessário para conectar ao RDS)
resource "aws_iam_role_policy_attachment" "lambda_cpf_auth_vpc" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.lambda_cpf_auth[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Permissão para API Gateway invocar a Lambda de Autenticação
resource "aws_lambda_permission" "api_gateway_cpf_auth" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cpf_auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.oficina_tech.execution_arn}/*/*"
}

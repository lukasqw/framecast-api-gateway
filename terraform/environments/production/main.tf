locals {
  aws_region = data.aws_region.current.name

  # openapi-spec.json e lambda/auth.zip ficam na raiz do repo (3 níveis acima)
  openapi_spec = templatefile("${path.module}/../../../openapi-spec.json", {
    api_title            = "Oficina Tech API - ${var.environment}"
    api_version          = "1.0"
    alb_endpoint         = local.alb_endpoint
    ms_identity_endpoint = local.ms_identity_endpoint
    ms_order_endpoint    = local.ms_order_endpoint
    ms_workshop_endpoint = local.ms_workshop_endpoint
    aws_region           = local.aws_region
    cpf_auth_lambda_arn  = module.lambda_auth.function_arn
  })

  common_tags = {
    Project     = "oficina-tech"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/oficina-tech-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "oficina-tech-api-gateway-logs-${var.environment}"
  })
}

# ── Lambda Function for CPF Authentication ────────────────────────────────────

module "lambda_auth" {
  source = "../../modules/lambda"

  filename      = "${path.module}/../../../lambda/auth.zip"
  function_name = "oficina-tech-cpf-auth-${var.environment}"
  role_arn      = local.lambda_execution_role_arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 512
  description   = "Lambda function for CPF-based authentication"

  environment_variables = {
    JWT_SECRET           = var.jwt_secret
    DB_HOST              = local.db_host
    DB_PORT              = local.db_port
    DB_USER              = local.db_user
    DB_PASSWORD          = var.db_password
    DB_NAME              = local.db_name
    DB_SSL               = var.db_ssl_enabled
    AWS_LAMBDA_LOG_LEVEL = "INFO"
  }

  vpc_subnet_ids         = coalesce(var.lambda_subnet_ids, local.lambda_subnet_ids)
  vpc_security_group_ids = coalesce(var.lambda_security_group_ids, local.lambda_security_group_ids)

  create_api_gateway_permission = false

  tags = merge(local.common_tags, {
    Name = "oficina-tech-cpf-auth"
  })
}

# ── API Gateway ───────────────────────────────────────────────────────────────

module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name        = "oficina-tech-api-${var.environment}"
  api_description = "API Gateway for Oficina Tech automotive workshop management system"
  openapi_spec    = local.openapi_spec
  stage_name      = var.stage_name

  enable_logging = var.enable_logging
  logging_level  = "INFO"
  log_group_arn  = aws_cloudwatch_log_group.api_gateway.arn

  enable_cache       = var.enable_cache
  cache_cluster_size = var.cache_cluster_size
  cache_ttl_seconds  = var.cache_ttl_seconds

  throttle_burst_limit = var.throttle_burst_limit
  throttle_rate_limit  = var.throttle_rate_limit
  quota_limit          = var.quota_limit

  usage_plan_name        = "oficina-tech-usage-plan-${var.environment}"
  usage_plan_description = "Usage plan for Oficina Tech API with rate limiting"

  enable_api_key = var.enable_api_key
  api_key_name   = "oficina-tech-api-key-${var.environment}"

  custom_domain_name = var.custom_domain_name
  certificate_arn    = var.certificate_arn
  base_path          = var.base_path

  tags = merge(local.common_tags, {
    Name = "oficina-tech-api-${var.environment}"
  })
}

# ── Lambda Permission ─────────────────────────────────────────────────────────

resource "aws_lambda_permission" "api_gateway_invoke_auth" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.rest_api_execution_arn}/*/*"
}

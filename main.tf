terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "oficina-tech"
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "api-gateway"
    }
  }
}

# Read and process OpenAPI specification
locals {
  openapi_spec_template = file("${path.module}/openapi-spec.json")
  openapi_spec = replace(
    replace(
      replace(
        replace(
          local.openapi_spec_template,
          "$${alb_endpoint}", var.alb_endpoint
        ),
        "$${authorizer_arn}", aws_lambda_function.jwt_authorizer.invoke_arn
      ),
      "$${api_title}", "Oficina Tech API - ${var.environment}"
    ),
    "$${api_version}", "1.0"
  )
}

# REST API Gateway from OpenAPI specification
resource "aws_api_gateway_rest_api" "oficina_tech" {
  name        = "oficina-tech-api-${var.environment}"
  description = "API Gateway for Oficina Tech automotive workshop management system"

  body = local.openapi_spec

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "oficina-tech-api-${var.environment}"
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "oficina_tech" {
  rest_api_id = aws_api_gateway_rest_api.oficina_tech.id

  triggers = {
    redeployment = sha1(local.openapi_spec)
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_rest_api.oficina_tech
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "oficina_tech" {
  deployment_id = aws_api_gateway_deployment.oficina_tech.id
  rest_api_id   = aws_api_gateway_rest_api.oficina_tech.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  xray_tracing_enabled = true

  tags = {
    Name = "oficina-tech-stage-${var.environment}"
  }
}

# Method Settings for all endpoints
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.oficina_tech.id
  stage_name  = aws_api_gateway_stage.oficina_tech.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    data_trace_enabled     = true
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/oficina-tech-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "oficina-tech-api-gateway-logs"
  }
}

# API Gateway Account (for CloudWatch logging)
resource "aws_api_gateway_account" "oficina_tech" {
  count               = var.use_lab_role ? 0 : 1
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch[0].arn
}

# IAM Role for API Gateway CloudWatch logging
resource "aws_iam_role" "api_gateway_cloudwatch" {
  count = var.use_lab_role ? 0 : 1
  name  = "oficina-tech-api-gateway-cloudwatch-${var.environment}"

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

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  count      = var.use_lab_role ? 0 : 1
  role       = aws_iam_role.api_gateway_cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

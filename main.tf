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
  aws_region            = data.aws_region.current.name
  openapi_spec = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                local.openapi_spec_template,
                "$${alb_endpoint}", var.alb_endpoint
              ),
              "$${authorizer_arn}", aws_lambda_function.jwt_authorizer.arn
            ),
            "$${authorizer_role_arn}", local.lambda_execution_role_arn
          ),
          "$${cpf_auth_lambda_arn}", aws_lambda_function.cpf_auth.arn
        ),
        "$${api_title}", "Oficina Tech API - ${var.environment}"
      ),
      "$${api_version}", "1.0"
    ),
    "$${AWS::Region}", local.aws_region
  )
}

# REST API Gateway from OpenAPI specification
resource "aws_api_gateway_rest_api" "oficina_tech" {
  name        = "oficina-tech-api-${var.environment}"
  description = "API Gateway for Oficina Tech automotive workshop management system"

  body = local.openapi_spec

  put_rest_api_mode = "merge"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "oficina-tech-api-${var.environment}"
  }

  depends_on = [
    aws_lambda_function.jwt_authorizer,
    aws_lambda_function.cpf_auth
  ]
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

  xray_tracing_enabled = false

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
    metrics_enabled        = false
    logging_level          = "OFF"
    data_trace_enabled     = false
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit
  }
}

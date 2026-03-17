terraform {
  required_version = ">= 1.0"

  # Remote backend configuration to prevent creating new resources on each deployment
  # This ensures the Terraform state is shared across GitHub Action runs
  # Using separate state key to isolate API Gateway from main infrastructure
  backend "s3" {
    bucket = "fiap-soat-tf-backend-bispo-730335587750"
    key    = "fiap/api-gateway/terraform.tfstate"
    region = "us-east-1"
  }

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

# Read and process OpenAPI specification using templatefile
locals {
  aws_region = data.aws_region.current.name

  openapi_spec = templatefile("${path.module}/openapi-template.json", {
    api_title           = "Oficina Tech API - ${var.environment}"
    api_version         = "1.0"
    alb_endpoint        = local.alb_endpoint
    aws_region          = local.aws_region
    authorizer_arn      = aws_lambda_function.jwt_authorizer.arn
    authorizer_role_arn = local.lambda_execution_role_arn
    cpf_auth_lambda_arn = aws_lambda_function.cpf_auth.arn
  })
}

# REST API Gateway from OpenAPI specification
resource "aws_api_gateway_rest_api" "oficina_tech" {
  name        = "oficina-tech-api-${var.environment}"
  description = "API Gateway for Oficina Tech automotive workshop management system"

  body = local.openapi_spec

  # Use "overwrite" to ensure all changes are applied
  # "merge" can miss some updates, especially in integration configurations
  put_rest_api_mode = "overwrite"

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
    # Force redeployment when OpenAPI spec changes
    redeployment = sha1(local.openapi_spec)
    # Also add timestamp to ensure deployment on every apply
    timestamp = timestamp()
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
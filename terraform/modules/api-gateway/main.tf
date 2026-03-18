# ============================================================================
# API Gateway Module
# ============================================================================

# REST API Gateway from OpenAPI specification
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = var.api_description

  body = var.openapi_spec

  put_rest_api_mode = "overwrite"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(var.openapi_spec)
    timestamp    = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name

  xray_tracing_enabled = var.xray_tracing_enabled

  # Access logging configuration
  dynamic "access_log_settings" {
    for_each = var.enable_logging ? [1] : []
    content {
      destination_arn = var.log_group_arn
      format = jsonencode({
        requestId                   = "$context.requestId"
        ip                          = "$context.identity.sourceIp"
        caller                      = "$context.identity.caller"
        user                        = "$context.identity.user"
        requestTime                 = "$context.requestTime"
        httpMethod                  = "$context.httpMethod"
        resourcePath                = "$context.resourcePath"
        status                      = "$context.status"
        protocol                    = "$context.protocol"
        responseLength              = "$context.responseLength"
        errorMessage                = "$context.error.message"
        integrationErrorMessage     = "$context.integrationErrorMessage"
      })
    }
  }

  # Cache configuration
  cache_cluster_enabled = var.enable_cache
  cache_cluster_size    = var.enable_cache ? var.cache_cluster_size : null

  tags = var.tags
}

# Method Settings for all endpoints
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = var.enable_logging
    logging_level          = var.enable_logging ? var.logging_level : "OFF"
    data_trace_enabled     = var.enable_logging
    throttling_burst_limit = var.throttle_burst_limit
    throttling_rate_limit  = var.throttle_rate_limit

    # Caching settings
    caching_enabled      = var.enable_cache
    cache_ttl_in_seconds = var.enable_cache ? var.cache_ttl_seconds : null
    cache_data_encrypted = var.enable_cache ? true : null
  }
}

# Usage Plan for Rate Limiting
resource "aws_api_gateway_usage_plan" "this" {
  name        = var.usage_plan_name
  description = var.usage_plan_description

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    period = "DAY"
  }

  throttle_settings {
    burst_limit = var.throttle_burst_limit
    rate_limit  = var.throttle_rate_limit
  }

  tags = var.tags
}

# API Key (optional)
resource "aws_api_gateway_api_key" "this" {
  count = var.enable_api_key ? 1 : 0

  name        = var.api_key_name
  description = "API Key for ${var.api_name}"
  enabled     = true

  tags = var.tags
}

# Associate API Key with Usage Plan
resource "aws_api_gateway_usage_plan_key" "this" {
  count = var.enable_api_key ? 1 : 0

  key_id        = aws_api_gateway_api_key.this[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}

# Custom Domain Name (optional)
resource "aws_api_gateway_domain_name" "this" {
  count = var.custom_domain_name != "" ? 1 : 0

  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# Base Path Mapping for Custom Domain
resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.custom_domain_name != "" ? 1 : 0

  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
  base_path   = var.base_path
}

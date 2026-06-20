locals {
  openapi_spec = templatefile("${path.module}/../../../openapi-spec.json", {
    framecast_api_endpoint = local.framecast_api_endpoint
    vpc_link_id            = local.vpc_link_id
    connection_type        = local.connection_type
    aws_region             = local.aws_region
  })
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/framecast-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "framecast-api-gateway-logs-${var.environment}"
  })
}

# ── VPC Link ──────────────────────────────────────────────────────────────────

module "vpc_link" {
  source = "../../modules/vpc-link"

  name    = "framecast-vpc-link-${var.environment}"
  nlb_arn = local.nlb_arn
  enabled = var.enable_vpc_link

  tags = merge(local.common_tags, {
    Name = "framecast-vpc-link-${var.environment}"
  })
}

# ── API Gateway ───────────────────────────────────────────────────────────────

module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name        = "framecast-api-gw-${var.environment}"
  api_description = "Framecast API Gateway — WAF + VPC Link → NLB:30080 → framecast-api"
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

  usage_plan_name        = "framecast-usage-plan-${var.environment}"
  usage_plan_description = "Usage plan for Framecast API with rate limiting"

  enable_api_key = var.enable_api_key
  api_key_name   = "framecast-api-key-${var.environment}"

  custom_domain_name = var.custom_domain_name
  certificate_arn    = var.certificate_arn

  tags = merge(local.common_tags, {
    Name = "framecast-api-gw-${var.environment}"
  })
}

# ── WAF ───────────────────────────────────────────────────────────────────────

module "waf" {
  source = "../../modules/waf"

  name         = "framecast-waf-${var.environment}"
  enabled      = var.enable_waf
  rate_limit   = var.waf_rate_limit
  resource_arn = local.stage_arn

  tags = merge(local.common_tags, {
    Name = "framecast-waf-${var.environment}"
  })

  depends_on = [module.api_gateway]
}

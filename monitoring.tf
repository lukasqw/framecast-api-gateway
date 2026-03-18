# ============================================================================
# CloudWatch Alarms and Monitoring
# ============================================================================

# CloudWatch Alarm for 5XX Errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "oficina-tech-api-5xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold_5xx
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = module.api_gateway.rest_api_name
    Stage   = module.api_gateway.stage_name
  }

  tags = merge(
    local.common_tags,
    {
      Name = "oficina-tech-api-5xx-alarm-${var.environment}"
    }
  )
}

# CloudWatch Alarm for 4XX Errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx_errors" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "oficina-tech-api-4xx-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold_4xx
  alarm_description   = "This metric monitors API Gateway 4XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = module.api_gateway.rest_api_name
    Stage   = module.api_gateway.stage_name
  }

  tags = merge(
    local.common_tags,
    {
      Name = "oficina-tech-api-4xx-alarm-${var.environment}"
    }
  )
}

# CloudWatch Alarm for Latency
resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "oficina-tech-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = var.latency_threshold_ms
  alarm_description   = "This metric monitors API Gateway latency"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = module.api_gateway.rest_api_name
    Stage   = module.api_gateway.stage_name
  }

  tags = merge(
    local.common_tags,
    {
      Name = "oficina-tech-api-latency-alarm-${var.environment}"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "framecast-api-5xx-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold_5xx
  alarm_description   = "Framecast API Gateway 5XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = module.api_gateway.rest_api_name
    Stage   = module.api_gateway.stage_name
  }

  tags = merge(local.common_tags, {
    Name = "framecast-api-5xx-alarm-${var.environment}"
  })
}

resource "aws_cloudwatch_metric_alarm" "api_4xx" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "framecast-api-4xx-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold_4xx
  alarm_description   = "Framecast API Gateway 4XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = module.api_gateway.rest_api_name
    Stage   = module.api_gateway.stage_name
  }

  tags = merge(local.common_tags, {
    Name = "framecast-api-4xx-alarm-${var.environment}"
  })
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "framecast-api-latency-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = var.latency_threshold_ms
  alarm_description   = "Framecast API Gateway latency"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = module.api_gateway.rest_api_name
    Stage   = module.api_gateway.stage_name
  }

  tags = merge(local.common_tags, {
    Name = "framecast-api-latency-alarm-${var.environment}"
  })
}

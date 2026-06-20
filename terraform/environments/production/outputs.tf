# ── API Gateway ───────────────────────────────────────────────────────────────

output "api_gateway_url" {
  description = "Framecast public entry point — WAF → VPC Link → NLB:30080 → framecast-api"
  value       = module.api_gateway.stage_invoke_url
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = module.api_gateway.rest_api_id
}

output "api_gateway_stage" {
  description = "API Gateway stage name"
  value       = module.api_gateway.stage_name
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  value       = module.api_gateway.rest_api_execution_arn
}

# ── VPC Link ──────────────────────────────────────────────────────────────────

output "vpc_link_id" {
  description = "VPC Link ID (empty when enable_vpc_link=false)"
  value       = module.vpc_link.vpc_link_id
}

# ── WAF ───────────────────────────────────────────────────────────────────────

output "waf_acl_arn" {
  description = "WAFv2 WebACL ARN (empty when enable_waf=false)"
  value       = module.waf.waf_acl_arn
}

# ── Usage Plan ────────────────────────────────────────────────────────────────

output "usage_plan_id" {
  description = "API Gateway Usage Plan ID"
  value       = module.api_gateway.usage_plan_id
}

# ── CloudWatch ────────────────────────────────────────────────────────────────

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for API Gateway access logs"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

# ── Backend ───────────────────────────────────────────────────────────────────

output "framecast_api_endpoint_configured" {
  description = "Effective framecast-api endpoint used by the gateway"
  value       = local.framecast_api_endpoint
}

# ── Test ──────────────────────────────────────────────────────────────────────

output "test_health_command" {
  description = "curl command to verify the gateway is reachable"
  value       = "curl -s ${module.api_gateway.stage_invoke_url}/health"
}

output "test_login_command" {
  description = "curl command to test POST /api/auth/login"
  value       = "curl -X POST ${module.api_gateway.stage_invoke_url}/api/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"user@example.com\",\"password\":\"password123\"}'"
}

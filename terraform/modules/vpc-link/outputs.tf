output "vpc_link_id" {
  description = "VPC Link ID (empty string when disabled)"
  value       = var.enabled ? aws_api_gateway_vpc_link.this[0].id : ""
}

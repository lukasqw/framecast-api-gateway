output "waf_acl_arn" {
  description = "WAFv2 WebACL ARN (empty string when disabled)"
  value       = var.enabled ? aws_wafv2_web_acl.this[0].arn : ""
}

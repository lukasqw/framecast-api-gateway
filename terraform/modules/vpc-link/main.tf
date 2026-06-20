resource "aws_api_gateway_vpc_link" "this" {
  count = var.enabled ? 1 : 0

  name        = var.name
  description = "VPC Link for ${var.name} → NLB"
  target_arns = [var.nlb_arn]

  tags = var.tags
}

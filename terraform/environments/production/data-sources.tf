data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "framecast/infra/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  aws_region   = data.aws_region.current.name
  lab_role_arn = var.lab_role != "" ? var.lab_role : "arn:aws:iam::${local.account_id}:role/LabRole"

  nlb_dns = try(data.terraform_remote_state.infra.outputs.nlb_dns_name, "placeholder.elb.us-east-1.amazonaws.com")
  nlb_arn = try(data.terraform_remote_state.infra.outputs.nlb_arn, "")

  framecast_api_endpoint = var.framecast_api_endpoint != "" ? var.framecast_api_endpoint : "${local.nlb_dns}:${var.nodeport}"

  vpc_link_id     = var.enable_vpc_link ? module.vpc_link.vpc_link_id : ""
  connection_type = var.enable_vpc_link ? "VPC_LINK" : "INTERNET"

  stage_arn = "arn:aws:apigateway:${local.aws_region}::/restapis/${module.api_gateway.rest_api_id}/stages/${module.api_gateway.stage_name}"

  common_tags = {
    Project     = "framecast"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

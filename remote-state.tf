# Data source to read outputs from the main infrastructure
data "terraform_remote_state" "backend" {
  backend = "s3"

  config = {
    bucket = "fiap-soat-tf-backend-bispo-730335587750"
    key    = "fiap/terraform.tfstate"
    region = "us-east-1"
  }
}

# Local values derived from remote state
locals {
  # Database configuration from remote state
  db_host = data.terraform_remote_state.backend.outputs.rds_address
  db_port = data.terraform_remote_state.backend.outputs.rds_port
  db_name = data.terraform_remote_state.backend.outputs.rds_database_name
  db_user = data.terraform_remote_state.backend.outputs.rds_username

  # VPC and networking from remote state
  vpc_id                    = data.terraform_remote_state.backend.outputs.vpc_id
  lambda_subnet_ids         = data.terraform_remote_state.backend.outputs.private_subnet_ids
  lambda_security_group_ids = [data.terraform_remote_state.backend.outputs.rds_security_group_id]

  # AWS region from remote state
  aws_region_from_backend = data.terraform_remote_state.backend.outputs.aws_region

  # ALB endpoint from remote state (fallback to variable if not available)
  alb_endpoint_from_state = try(data.terraform_remote_state.backend.outputs.alb_dns_name, null)
}

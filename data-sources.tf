# Data source to get AWS Account ID
data "aws_caller_identity" "current" {}

# Data source to get AWS Region
data "aws_region" "current" {}

# Data source to read remote state from main infrastructure
data "terraform_remote_state" "main" {
  backend = "s3"
  config = {
    bucket = "fiap-soat-tf-backend-bispo-730335587750"
    key    = "fiap/terraform.tfstate"
    region = "us-east-1"
  }
}

# Construir ARNs automaticamente usando o Account ID atual
locals {
  account_id = data.aws_caller_identity.current.account_id

  # Usar variável se fornecida, senão construir automaticamente
  lab_role_arn = var.lab_role != "" ? var.lab_role : "arn:aws:iam::${local.account_id}:role/LabRole"

  # ARN para execução das Lambdas
  lambda_execution_role_arn = local.lab_role_arn

  # ALB endpoint: usar variável se fornecida, senão tentar do remote state, senão usar fallback
  alb_endpoint = var.alb_endpoint != "" ? var.alb_endpoint : try(
    data.terraform_remote_state.main.outputs.alb_endpoint,
    "http://aec1d4f7c5cc34ff2b3bfa04191b20cd-5d482ef2dd2d10ed.elb.us-east-1.amazonaws.com"
  )

  # Database configuration from remote state
  db_host = try(data.terraform_remote_state.main.outputs.db_host, "localhost")
  db_port = try(data.terraform_remote_state.main.outputs.db_port, "5432")
  db_name = try(data.terraform_remote_state.main.outputs.db_name, "oficina_tech")
  db_user = try(data.terraform_remote_state.main.outputs.db_user, "postgres")

  # Lambda VPC configuration from remote state
  lambda_subnet_ids         = coalesce(var.lambda_subnet_ids, try(data.terraform_remote_state.main.outputs.lambda_subnet_ids, []))
  lambda_security_group_ids = coalesce(var.lambda_security_group_ids, try(data.terraform_remote_state.main.outputs.lambda_security_group_ids, []))
}

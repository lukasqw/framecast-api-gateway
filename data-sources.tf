# Data source to get AWS Account ID
data "aws_caller_identity" "current" {}

# Data source to get AWS Region
data "aws_region" "current" {}

# Data source to read remote state from main infrastructure
data "terraform_remote_state" "main" {
  backend = "s3"
  config = {
    bucket = "fiap-soat-tf-backend-bispo-730335587750"
    key    = "fiap/infra/terraform.tfstate"
    region = "us-east-1"
  }
}

# Data source to read remote state from database infrastructure
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "fiap-soat-tf-backend-bispo-730335587750"
    key    = "fiap/db/terraform.tfstate"
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

  # NLB base DNS (used to build per-MS endpoints below)
  nlb_dns = try(data.terraform_remote_state.main.outputs.nlb_dns_name, "placeholder.elb.us-east-1.amazonaws.com")

  # Legacy single-backend endpoint (kept for compatibility)
  alb_endpoint = var.alb_endpoint != "" ? var.alb_endpoint : "http://${local.nlb_dns}"

  # Per-microservice endpoints: override via var or auto-build from NLB DNS + NodePort
  ms_identity_endpoint = var.ms_identity_endpoint != "" ? var.ms_identity_endpoint : "http://${local.nlb_dns}:30081"
  ms_order_endpoint    = var.ms_order_endpoint != "" ? var.ms_order_endpoint : "http://${local.nlb_dns}:30082"
  ms_workshop_endpoint = var.ms_workshop_endpoint != "" ? var.ms_workshop_endpoint : "http://${local.nlb_dns}:30083"

  # Lambda Auth connects to db_ms1 (ms-identity) — queries users and customers tables
  db_host = try(data.terraform_remote_state.db.outputs.rds_ms1_address, "localhost")
  db_port = try(data.terraform_remote_state.db.outputs.rds_ms1_port, "5432")
  db_name = try(data.terraform_remote_state.db.outputs.rds_ms1_database_name, "db_ms1")
  db_user = try(data.terraform_remote_state.db.outputs.rds_ms1_username, "postgres")

  # Lambda VPC configuration from infra remote state
  lambda_subnet_ids         = coalesce(var.lambda_subnet_ids, try(data.terraform_remote_state.main.outputs.subnet_ids, []))
  lambda_security_group_ids = coalesce(var.lambda_security_group_ids, try([data.terraform_remote_state.main.outputs.eks_security_group_id], []))
}

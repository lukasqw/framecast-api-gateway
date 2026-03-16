# Data source to get AWS Account ID
data "aws_caller_identity" "current" {}

# Data source to get AWS Region
data "aws_region" "current" {}

# Construir ARNs automaticamente usando o Account ID atual
locals {
  account_id = data.aws_caller_identity.current.account_id

  # Usar variável se fornecida, senão construir automaticamente
  lab_role_arn  = var.lab_role != "" ? var.lab_role : "arn:aws:iam::${local.account_id}:role/LabRole"
  principal_arn = var.principal_arn != "" ? var.principal_arn : "arn:aws:iam::${local.account_id}:role/voclabs"

  # ARN para execução das Lambdas
  lambda_execution_role_arn = local.lab_role_arn
}

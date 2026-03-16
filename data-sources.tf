# Data source to get AWS Account ID
data "aws_caller_identity" "current" {}

# Data source to get AWS Region
data "aws_region" "current" {}

# Data source to get LabRole ARN (for AWS Academy environments)
data "aws_iam_role" "lab_role" {
  count = var.use_lab_role ? 1 : 0
  name  = "LabRole"
}

# Local variable to determine which role to use
locals {
  lambda_execution_role_arn = var.use_lab_role ? data.aws_iam_role.lab_role[0].arn : null
}

# Security Group Rule para permitir Lambda acessar RDS
# O Lambda usa o security group do EKS, então precisamos permitir conexões dele para o RDS
# NOTA: Esta regra já existe no RDS security group, então vamos apenas referenciá-la via data source

# Importar a regra existente em vez de criar uma nova
# Para importar: terraform import 'aws_security_group_rule.lambda_to_rds[0]' 'sg-04f6064fb77f9be57_ingress_tcp_5432_5432_sg-05c5bf89b90e1fe6f'

data "aws_security_group" "rds" {
  id = try(data.terraform_remote_state.main.outputs.rds_security_group_id, null)
  
  # Só buscar se o ID existir
  count = try(data.terraform_remote_state.main.outputs.rds_security_group_id, null) != null ? 1 : 0
}

# Comentado porque a regra já existe no security group do RDS
# Se precisar gerenciar via Terraform, importe primeiro com:
# terraform import 'aws_security_group_rule.lambda_to_rds[0]' 'sg-04f6064fb77f9be57_ingress_tcp_5432_5432_sg-05c5bf89b90e1fe6f'
#
# resource "aws_security_group_rule" "lambda_to_rds" {
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   source_security_group_id = try(data.terraform_remote_state.main.outputs.eks_security_group_id, null)
#   security_group_id        = try(data.terraform_remote_state.main.outputs.rds_security_group_id, null)
#   description              = "Allow Lambda (via EKS SG) to access RDS PostgreSQL"
#   count = try(data.terraform_remote_state.main.outputs.rds_security_group_id, null) != null ? 1 : 0
# }

# Output para debug
output "lambda_security_groups" {
  description = "Security groups usados pelo Lambda"
  value       = local.lambda_security_group_ids
}

output "lambda_subnets" {
  description = "Subnets usadas pelo Lambda"
  value       = local.lambda_subnet_ids
}

output "db_host_configured" {
  description = "DB Host configurado no Lambda"
  value       = local.db_host
  sensitive   = false
}

output "db_connection_string" {
  description = "String de conexão do banco (sem senha)"
  value       = "postgresql://${local.db_user}@${local.db_host}:${local.db_port}/${local.db_name}"
  sensitive   = false
}

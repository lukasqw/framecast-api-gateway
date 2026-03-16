#!/bin/bash

# NOTA: Este script não é mais necessário com o backend S3 remoto configurado!
# O Terraform agora gerencia o estado corretamente e atualiza as Lambdas existentes
# em vez de tentar criar novas. Mantido apenas para casos de emergência.

# Script para limpar Lambdas existentes antes do deploy
# Use este script quando o pipeline falhar por conflito de Lambdas

set -e

echo "🧹 Limpando funções Lambda existentes..."

# Configurar variáveis
ENVIRONMENT=${1:-production}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"

# Nomes das funções Lambda
CPF_AUTH_FUNCTION="oficina-tech-cpf-auth-${ENVIRONMENT}"
JWT_AUTHORIZER_FUNCTION="oficina-tech-jwt-authorizer-${ENVIRONMENT}"

# Função para remover Lambda se existir
remove_lambda_if_exists() {
    local function_name=$1
    
    echo "🔍 Verificando $function_name..."
    
    if aws lambda get-function --function-name "$function_name" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo "🗑️  Removendo $function_name..."
        aws lambda delete-function --function-name "$function_name" --region "$AWS_REGION"
        echo "✅ $function_name removida"
    else
        echo "ℹ️  $function_name não existe"
    fi
}

# Remover as Lambdas
remove_lambda_if_exists "$CPF_AUTH_FUNCTION"
remove_lambda_if_exists "$JWT_AUTHORIZER_FUNCTION"

echo "🎉 Limpeza concluída! Agora você pode executar o terraform apply"
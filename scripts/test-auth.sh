#!/bin/bash

# Script para testar a Lambda de autenticação via CPF
# Uso: ./test-auth.sh [API_ENDPOINT]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuração
API_ENDPOINT="${1:-https://your-api-gateway.execute-api.us-east-1.amazonaws.com/v1}"
AUTH_ENDPOINT="${API_ENDPOINT}/auth/login"

echo -e "${YELLOW}=== Teste de Autenticação via CPF ===${NC}\n"

# Função para testar autenticação
test_auth() {
    local cpf=$1
    local password=$2
    local type=$3
    local description=$4

    echo -e "${YELLOW}Testando: ${description}${NC}"
    echo "CPF: ${cpf}"
    echo "Type: ${type}"
    echo ""

    response=$(curl -s -w "\n%{http_code}" -X POST "${AUTH_ENDPOINT}" \
        -H "Content-Type: application/json" \
        -d "{\"cpf\":\"${cpf}\",\"password\":\"${password}\",\"type\":\"${type}\"}")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Sucesso (HTTP ${http_code})${NC}"
        echo "$body" | jq '.'
        
        # Extrair e salvar token
        token=$(echo "$body" | jq -r '.token')
        if [ "$token" != "null" ]; then
            echo -e "\n${GREEN}Token JWT:${NC}"
            echo "$token"
            echo "$token" > /tmp/oficina_tech_token.txt
            echo -e "\n${GREEN}Token salvo em: /tmp/oficina_tech_token.txt${NC}"
        fi
    else
        echo -e "${RED}✗ Falha (HTTP ${http_code})${NC}"
        echo "$body" | jq '.'
    fi
    
    echo -e "\n---\n"
}

# Teste 1: Autenticação de cliente com CPF válido
echo -e "${YELLOW}Teste 1: Cliente com CPF válido${NC}"
test_auth "123.456.789-00" "senha123" "customer" "Cliente válido"

# Teste 2: Autenticação de usuário com CPF válido
echo -e "${YELLOW}Teste 2: Usuário com CPF válido${NC}"
test_auth "987.654.321-00" "senha456" "user" "Usuário válido"

# Teste 3: CPF sem formatação
echo -e "${YELLOW}Teste 3: CPF sem formatação${NC}"
test_auth "12345678900" "senha123" "customer" "CPF sem pontos e traços"

# Teste 4: CPF inválido (formato)
echo -e "${YELLOW}Teste 4: CPF inválido (formato)${NC}"
test_auth "123.456.789" "senha123" "customer" "CPF incompleto"

# Teste 5: CPF inválido (dígitos verificadores)
echo -e "${YELLOW}Teste 5: CPF inválido (dígitos verificadores)${NC}"
test_auth "123.456.789-99" "senha123" "customer" "Dígitos verificadores incorretos"

# Teste 6: Senha incorreta
echo -e "${YELLOW}Teste 6: Senha incorreta${NC}"
test_auth "123.456.789-00" "senhaerrada" "customer" "Senha incorreta"

# Teste 7: Tipo inválido
echo -e "${YELLOW}Teste 7: Tipo inválido${NC}"
test_auth "123.456.789-00" "senha123" "invalid" "Tipo inválido"

# Teste 8: Campos faltando
echo -e "${YELLOW}Teste 8: Campos obrigatórios faltando${NC}"
echo "Testando sem CPF..."
curl -s -X POST "${AUTH_ENDPOINT}" \
    -H "Content-Type: application/json" \
    -d '{"password":"senha123","type":"customer"}' | jq '.'
echo ""

# Teste 9: Testar token em endpoint protegido
if [ -f /tmp/oficina_tech_token.txt ]; then
    echo -e "${YELLOW}Teste 9: Usar token em endpoint protegido${NC}"
    token=$(cat /tmp/oficina_tech_token.txt)
    
    echo "Testando GET /customers com token..."
    response=$(curl -s -w "\n%{http_code}" -X GET "${API_ENDPOINT}/customers" \
        -H "Authorization: Bearer ${token}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Token válido - Acesso autorizado (HTTP ${http_code})${NC}"
    else
        echo -e "${RED}✗ Token inválido ou endpoint não acessível (HTTP ${http_code})${NC}"
    fi
    echo "$body" | jq '.'
    echo ""
fi

# Teste 10: Validação de CPFs conhecidos como inválidos
echo -e "${YELLOW}Teste 10: CPFs conhecidos como inválidos${NC}"
invalid_cpfs=("111.111.111-11" "000.000.000-00" "999.999.999-99")

for cpf in "${invalid_cpfs[@]}"; do
    echo "Testando CPF inválido: ${cpf}"
    response=$(curl -s -X POST "${AUTH_ENDPOINT}" \
        -H "Content-Type: application/json" \
        -d "{\"cpf\":\"${cpf}\",\"password\":\"senha123\",\"type\":\"customer\"}")
    
    error=$(echo "$response" | jq -r '.error')
    if [ "$error" == "CPF inválido" ]; then
        echo -e "${GREEN}✓ CPF corretamente rejeitado${NC}"
    else
        echo -e "${RED}✗ CPF deveria ser rejeitado${NC}"
        echo "$response" | jq '.'
    fi
    echo ""
done

echo -e "${GREEN}=== Testes concluídos ===${NC}"
echo ""
echo "Resumo:"
echo "- Endpoint testado: ${AUTH_ENDPOINT}"
echo "- Token salvo em: /tmp/oficina_tech_token.txt (se autenticação bem-sucedida)"
echo ""
echo "Para testar com seus próprios dados:"
echo "  ./test-auth.sh https://your-api-gateway.execute-api.us-east-1.amazonaws.com/v1"

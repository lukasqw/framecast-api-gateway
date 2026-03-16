# Setup da Lambda de Autenticação via CPF

## Resumo das Alterações

Foi implementada uma nova Lambda function serverless para autenticação via CPF que:

✅ Valida CPF do cliente e do usuário  
✅ Consulta existência e status na base de dados PostgreSQL  
✅ Gera e retorna token JWT válido para consumo das APIs protegidas  
✅ Protege rotas sensíveis da aplicação com autenticação via CPF

## Arquivos Criados

### Lambda Function

- `lambda/auth/index.js` - Código da Lambda de autenticação
- `lambda/auth/package.json` - Dependências Node.js
- `lambda/auth/README.md` - Documentação completa da Lambda

### Terraform

- `auth-lambda.tf` - Infraestrutura da Lambda (função, IAM, logs)

### OpenAPI

- `openapi/paths/auth.json` - Definição do endpoint `/auth/login`

### Documentação

- `LAMBDA_AUTH_SETUP.md` - Este arquivo

## Arquivos Modificados

- `variables.tf` - Adicionadas variáveis de banco de dados e VPC
- `terraform.tfvars.example` - Exemplo com novas variáveis
- `Makefile` - Comandos para build e logs da Lambda de autenticação

## Pré-requisitos

### 1. Banco de Dados RDS PostgreSQL

A Lambda precisa acessar o RDS PostgreSQL onde estão as tabelas:

- `customers` (clientes com CPF)
- `users` (usuários do sistema com CPF)

### 2. Configuração VPC

A Lambda deve estar na mesma VPC do RDS:

- **Subnets**: Subnets privadas com acesso ao RDS
- **Security Groups**: Permitir tráfego de saída para RDS na porta 5432

### 3. Variáveis de Ambiente

Configure no arquivo `terraform.tfvars`:

```hcl
# Database Configuration
db_host     = "your-rds-endpoint.us-east-1.rds.amazonaws.com"
db_port     = "5432"
db_user     = "postgres"
db_password = "your-secure-password"
db_name     = "oficina_tech_db"
db_ssl_enabled = "true"

# VPC Configuration
lambda_subnet_ids         = ["subnet-xxxxx", "subnet-yyyyy"]
lambda_security_group_ids = ["sg-xxxxx"]

# JWT Secret (deve ser o mesmo do backend)
jwt_secret = "your-jwt-secret-key-min-32-characters"
```

## Deploy

### 1. Build da Lambda

```bash
cd lambda/auth
make build-lambda-auth
```

Isso criará o arquivo `lambda/auth.zip` com o código e dependências.

### 2. Deploy com Terraform

```bash
# Validar configuração
make validate

# Planejar mudanças
make plan

# Aplicar mudanças
make apply
```

### 3. Verificar Deploy

```bash
# Ver outputs do Terraform
make output

# Verificar logs da Lambda
make logs-lambda-auth
```

## Endpoint de Autenticação

### POST /auth/login

Autentica cliente ou usuário via CPF e retorna token JWT.

**Request:**

```json
{
  "cpf": "123.456.789-00",
  "password": "senha123",
  "type": "customer"
}
```

**Response (200 OK):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "customer",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "João Silva",
    "email": "joao@example.com",
    "cpf": "12345678900",
    "role": "CUSTOMER"
  }
}
```

## Fluxo de Autenticação

```
1. Cliente/App → POST /auth/login (CPF + senha)
                    ↓
2. API Gateway → Lambda de Autenticação
                    ↓
3. Lambda → Valida CPF (formato + dígitos verificadores)
                    ↓
4. Lambda → Consulta PostgreSQL (customers ou users)
                    ↓
5. Lambda → Verifica senha (bcrypt)
                    ↓
6. Lambda → Gera JWT (válido por 24h)
                    ↓
7. API Gateway → Retorna token ao cliente
                    ↓
8. Cliente → Usa token em requisições protegidas
   Header: Authorization: Bearer <token>
```

## Proteção de Rotas

Após obter o token, use-o no header `Authorization` para acessar rotas protegidas:

```bash
curl -X GET https://api.example.com/v1/customers \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

O API Gateway usa a Lambda Authorizer existente (`lambda/index.js`) para validar o token JWT em todas as rotas protegidas.

## Validação de CPF

A Lambda implementa validação completa:

1. ✅ Remove formatação (pontos e traços)
2. ✅ Verifica 11 dígitos
3. ✅ Rejeita sequências inválidas (111.111.111-11)
4. ✅ Valida dígitos verificadores (algoritmo módulo 11)

## Segurança

- ✅ Conexão SSL com banco de dados
- ✅ Lambda em VPC privada
- ✅ Senhas verificadas com bcrypt
- ✅ Tokens JWT com expiração
- ✅ Logs detalhados no CloudWatch
- ✅ IAM roles com permissões mínimas

## Monitoramento

### CloudWatch Logs

```bash
# Logs da Lambda de autenticação
make logs-lambda-auth

# Logs do API Gateway
make logs-api
```

### Métricas

Acesse CloudWatch Metrics para monitorar:

- Invocações da Lambda
- Duração de execução
- Erros e throttling
- Conexões ao banco de dados

## Troubleshooting

### Lambda não conecta ao RDS

Verifique:

1. Lambda está nas mesmas subnets do RDS
2. Security Group permite tráfego de saída para RDS:5432
3. RDS permite tráfego de entrada do Security Group da Lambda

### Erro "CPF inválido"

Verifique:

1. CPF tem 11 dígitos
2. Dígitos verificadores estão corretos
3. Não é uma sequência inválida (111.111.111-11)

### Erro "Cliente não encontrado"

Verifique:

1. CPF existe na tabela `customers` ou `users`
2. Campo `document_type` é 'CPF' (para customers)
3. Registro não está deletado (`deleted_at IS NULL`)

### Token inválido

Verifique:

1. `JWT_SECRET` é o mesmo no backend e na Lambda
2. Token não expirou (válido por 24h)
3. Token está no formato correto: `Bearer <token>`

## Custos Estimados

Para tráfego baixo/médio:

- **Lambda Invocações**: ~$0.20/milhão
- **Lambda Duração**: ~$0.0000166667/GB-segundo
- **CloudWatch Logs**: ~$0.50/GB
- **VPC ENI**: ~$0.01/hora

**Total estimado**: < $5/mês para até 100k autenticações/mês

## Próximos Passos

1. ✅ Testar endpoint `/auth/login` com clientes e usuários reais
2. ✅ Configurar rate limiting no API Gateway
3. ✅ Implementar refresh tokens (opcional)
4. ✅ Adicionar MFA (autenticação multi-fator) - opcional
5. ✅ Configurar alarmes no CloudWatch
6. ✅ Documentar no Swagger/OpenAPI

## Suporte

Para dúvidas ou problemas:

1. Verifique logs no CloudWatch
2. Consulte `lambda/auth/README.md` para detalhes da implementação
3. Revise configurações no `terraform.tfvars`

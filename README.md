# API Gateway - Oficina Tech

API Gateway simplificado para AWS Academy com autenticação JWT e integração com backend.

## 🚀 Quick Start

### 1. Configurar Variáveis

```bash
# Copiar exemplo
cp terraform.tfvars.example terraform.tfvars

# Editar com seus valores
vim terraform.tfvars
```

### 2. Deploy

```bash
# Build e deploy
make build
make init
make plan
make apply
```

### 3. Testar

```bash
make test
```

## 📁 Estrutura Simplificada

```
├── main.tf                    # Configuração principal
├── authorizer.tf              # Lambda JWT authorizer
├── auth-lambda.tf             # Lambda autenticação CPF
├── variables.tf               # Variáveis
├── outputs.tf                 # Outputs
├── data-sources.tf            # Data sources
├── lambda/
│   ├── index.js              # JWT Authorizer
│   └── auth/
│       ├── index.js          # CPF Authentication
│       ├── utils.js          # Utilitários
│       └── package.json      # Dependências
├── openapi-template.json      # Template OpenAPI
├── scripts/
│   ├── build-openapi-consolidated.py
│   ├── test-auth.sh
│   └── test-endpoints.sh
└── Makefile                   # Comandos de automação
```

## 🔧 Comandos Disponíveis

```bash
make help          # Mostra comandos disponíveis
make build         # Constrói artefatos
make init          # Inicializa Terraform
make plan          # Planeja mudanças
make apply         # Aplica mudanças
make destroy       # Destrói recursos
make test          # Executa testes
make clean         # Limpa artefatos
make validate      # Valida configuração
make format        # Formata código
```

## 🏗️ Arquitetura

```
Client → API Gateway → Lambda Authorizer (JWT) → ALB → EKS Backend
                    ↓
                Lambda CPF Auth → PostgreSQL
```

## 🔒 Autenticação

### Endpoints Públicos

- `POST /auth/login` - Autenticação via CPF

### Endpoints Protegidos

- Todos os outros endpoints requerem JWT token
- Header: `Authorization: Bearer <token>`

## 📋 Configuração AWS Academy

### Variáveis Obrigatórias

```hcl
jwt_secret = "seu-jwt-secret"
db_password = "sua-senha-db"
```

### Limitações AWS Academy

- Sem WAF (removido)
- Sem CloudWatch avançado (removido)
- Sem CI/CD (removido)
- Configuração simplificada

## 🧪 Testes

```bash
# Testar autenticação
./scripts/test-auth.sh

# Testar endpoints
./scripts/test-endpoints.sh
```

## 📊 Monitoramento

- Logs básicos no CloudWatch
- Métricas padrão do API Gateway
- Logs das Lambda functions

## 🔧 Troubleshooting

### Problemas Comuns

1. **Deploy falha**: Verificar `terraform validate`
2. **Lambda errors**: Verificar logs no CloudWatch
3. **API 5XX**: Verificar se ALB está acessível

### Logs

```bash
# Ver logs das Lambdas
aws logs tail /aws/lambda/oficina-tech-cpf-auth-dev --follow
aws logs tail /aws/lambda/oficina-tech-jwt-authorizer-dev --follow
```

## 📝 Variáveis de Ambiente

### Lambda CPF Auth

- `JWT_SECRET`: Chave secreta JWT
- `DB_HOST`: Host do PostgreSQL
- `DB_PORT`: Porta do banco (5432)
- `DB_USER`: Usuário do banco
- `DB_PASSWORD`: Senha do banco
- `DB_NAME`: Nome do banco
- `DB_SSL`: SSL habilitado (true)

### Lambda Authorizer

- `JWT_SECRET`: Chave secreta JWT

---

**Versão simplificada para AWS Academy** - Funcionalidades essenciais mantidas, complexidade removida.

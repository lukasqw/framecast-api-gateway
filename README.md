# API Gateway - Oficina Tech

API Gateway profissional para AWS com autenticação JWT, rate limiting, monitoramento e boas práticas de mercado.

## 🚀 Características

### Segurança

- ✅ Autenticação JWT via Lambda (CPF-based)
- ✅ Validação de requests (body e parameters)
- ✅ CORS configurado corretamente
- ✅ Rate limiting e throttling
- ✅ API Keys (opcional)
- ✅ SSL/TLS encryption

### Performance

- ✅ Cache configurável por endpoint
- ✅ Connection pooling no PostgreSQL
- ✅ Timeouts otimizados
- ✅ Compressão de respostas

### Monitoramento

- ✅ CloudWatch Logs estruturados
- ✅ Métricas detalhadas
- ✅ Alarmes para erros 4XX/5XX
- ✅ Alarmes de latência
- ✅ Usage Plans e quotas

### Arquitetura

- ✅ OpenAPI 3.0 modular
- ✅ Componentes reutilizáveis
- ✅ Schemas validados
- ✅ Documentação automática
- ✅ Versionamento de API

## 📁 Estrutura do Projeto

```
├── main.tf                           # Configuração principal do API Gateway
├── api-gateway-config.tf             # Usage plans, alarms, logging
├── auth-lambda.tf                    # Lambda de autenticação CPF
├── variables.tf                      # Variáveis configuráveis
├── outputs.tf                        # Outputs úteis
├── data-sources.tf                   # Data sources e locals
├── security-groups.tf                # Security groups
├── lambda/
│   └── auth/
│       ├── index.js                  # Lambda handler (melhorado)
│       ├── utils.js                  # Utilitários
│       └── package.json              # Dependências
├── openapi-improved.json             # Base OpenAPI com components
├── openapi/
│   └── paths-improved/
│       ├── auth.json                 # Endpoints de autenticação
│       └── customers.json            # Endpoints de clientes
├── scripts/
│   ├── build-openapi-improved.py     # Build OpenAPI consolidado
│   ├── test-auth.sh                  # Testes de autenticação
│   └── test-endpoints.sh             # Testes de endpoints
├── Makefile                          # Comandos automatizados
└── README.md                         # Esta documentação
```

## 🔧 Pré-requisitos

- Terraform >= 1.0
- Python 3.x
- Node.js >= 18.x
- AWS CLI configurado
- Make (opcional, mas recomendado)

## 🚀 Quick Start

### 1. Configurar Variáveis

```bash
# Copiar exemplo
cp terraform.tfvars.example terraform.tfvars

# Editar com seus valores
vim terraform.tfvars
```

Variáveis obrigatórias:

```hcl
jwt_secret  = "seu-jwt-secret-super-seguro"
db_password = "sua-senha-db"
```

### 2. Build e Deploy

```bash
# Verificar dependências
make check-deps

# Build dos artefatos
make build

# Inicializar Terraform
make init

# Validar configuração
make validate

# Planejar mudanças
make plan

# Aplicar mudanças
make apply
```

Ou tudo de uma vez:

```bash
make apply-auto
```

### 3. Testar

```bash
# Executar testes
make test

# Ver outputs
make outputs
```

## 📋 Configuração Avançada

### Rate Limiting

```hcl
# terraform.tfvars
throttle_burst_limit = 5000    # Burst máximo
throttle_rate_limit  = 10000   # Requests por segundo
quota_limit          = 1000000 # Limite diário
```

### Logging e Monitoramento

```hcl
enable_logging      = true
log_retention_days  = 7
enable_alarms       = true
error_threshold_5xx = 10
error_threshold_4xx = 100
latency_threshold_ms = 5000
```

### Cache

```hcl
enable_cache        = true
cache_cluster_size  = "0.5"  # GB
cache_ttl_seconds   = 300    # 5 minutos
```

### API Key (Camada Extra de Segurança)

```hcl
enable_api_key = true
```

Após deploy, obter a chave:

```bash
terraform output api_key_value
```

### Custom Domain

```hcl
custom_domain_name = "api.oficinatech.com"
certificate_arn    = "arn:aws:acm:us-east-1:123456789:certificate/..."
base_path          = "v1"
```

## 🏗️ Arquitetura

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         API Gateway (Regional)          │
│  ┌────────────────────────────────────┐ │
│  │  Rate Limiting & Throttling        │ │
│  │  Request Validation                │ │
│  │  CORS                              │ │
│  │  Cache (opcional)                  │ │
│  └────────────────────────────────────┘ │
└──────┬──────────────────────┬───────────┘
       │                      │
       │ /auth/login          │ outros endpoints
       ▼                      ▼
┌──────────────┐      ┌──────────────┐
│ Lambda Auth  │      │  ALB → EKS   │
│  (CPF Auth)  │      │   Backend    │
└──────┬───────┘      └──────────────┘
       │
       ▼
┌──────────────┐
│  PostgreSQL  │
│     RDS      │
└──────────────┘
```

## 🔒 Autenticação

### Login

```bash
curl -X POST https://api-url/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "cpf": "12345678901",
    "password": "senha123",
    "type": "customer"
  }'
```

Resposta:

```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "name": "João Silva",
      "email": "joao@example.com",
      "cpf": "12345678901",
      "role": "CUSTOMER"
    }
  }
}
```

### Validar Token

```bash
curl -X POST https://api-url/v1/auth/validate \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

### Usar Token em Endpoints Protegidos

```bash
curl -X GET https://api-url/v1/customers \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

## 📊 Monitoramento

### CloudWatch Logs

```bash
# Ver logs da Lambda de autenticação
aws logs tail /aws/lambda/oficina-tech-cpf-auth-dev --follow

# Ver logs do API Gateway
aws logs tail /aws/apigateway/oficina-tech-dev --follow
```

### Métricas Disponíveis

- `4XXError` - Erros de cliente
- `5XXError` - Erros de servidor
- `Count` - Total de requests
- `Latency` - Latência das requests
- `CacheHitCount` - Cache hits
- `CacheMissCount` - Cache misses

### Alarmes Configurados

- **5XX Errors**: Alerta quando > 10 erros em 5 minutos
- **4XX Errors**: Alerta quando > 100 erros em 5 minutos
- **Latency**: Alerta quando latência média > 5 segundos

## 🧪 Testes

### Teste Manual

```bash
# Obter URL da API
API_URL=$(terraform output -raw api_gateway_url)

# Testar autenticação
curl -X POST $API_URL/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"cpf":"12345678901","password":"senha123","type":"customer"}'

# Salvar token
TOKEN="seu-token-aqui"

# Testar endpoint protegido
curl -X GET $API_URL/customers \
  -H "Authorization: Bearer $TOKEN"
```

### Scripts de Teste

```bash
# Executar todos os testes
make test

# Ou individualmente
bash scripts/test-auth.sh
bash scripts/test-endpoints.sh
```

## 🔧 Comandos Úteis

```bash
make help          # Mostrar todos os comandos
make check-deps    # Verificar dependências
make build         # Build dos artefatos
make init          # Inicializar Terraform
make validate      # Validar configuração
make format        # Formatar código
make lint          # Lint e validação
make plan          # Planejar mudanças
make apply         # Aplicar mudanças
make apply-auto    # Build + Plan + Apply
make destroy       # Destruir recursos
make clean         # Limpar artefatos
make test          # Executar testes
make outputs       # Mostrar outputs
make state-list    # Listar recursos no state
make fix-state     # Corrigir problemas de state
make upgrade       # Atualizar providers
```

## 📝 Variáveis de Ambiente

### Lambda CPF Auth

- `JWT_SECRET`: Chave secreta JWT (obrigatório)
- `DB_HOST`: Host do PostgreSQL
- `DB_PORT`: Porta do banco (5432)
- `DB_USER`: Usuário do banco
- `DB_PASSWORD`: Senha do banco (obrigatório)
- `DB_NAME`: Nome do banco
- `DB_SSL`: SSL habilitado (true/false)

## 🐛 Troubleshooting

### Erro: "Unauthorized"

- Verificar se o token JWT está válido
- Verificar se o header Authorization está correto: `Bearer {token}`
- Verificar se o JWT_SECRET está configurado corretamente

### Erro: "Rate Limit Exceeded"

- Aguardar 60 segundos
- Ajustar `throttle_rate_limit` e `throttle_burst_limit`

### Erro: "Internal Server Error"

- Verificar logs da Lambda: `aws logs tail /aws/lambda/oficina-tech-cpf-auth-dev --follow`
- Verificar conectividade com RDS
- Verificar security groups

### Deploy Falha

```bash
# Limpar state e reinicializar
make fix-state

# Validar configuração
make validate

# Tentar novamente
make apply
```

## 📚 Documentação Adicional

- [OpenAPI Specification](./openapi-improved.json)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/best-practices.html)

## 🔄 Versionamento

- API Version: v1
- OpenAPI Version: 3.0.0
- Terraform Version: >= 1.0
- AWS Provider Version: ~> 5.0

## 📄 Licença

MIT License - Oficina Tech

---

**Desenvolvido com ❤️ seguindo as melhores práticas de mercado**

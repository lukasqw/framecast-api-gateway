# Quick Start - API Gateway

Guia rápido para começar a usar o API Gateway baseado em OpenAPI.

## ⚡ Setup Rápido (5 minutos)

```bash
# 1. Verificar dependências
make check-deps

# 2. Configurar variáveis
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Editar com suas configurações

# 3. Setup completo
make setup

# 4. Deploy
make apply
```

## 📋 Pré-requisitos

- Terraform >= 1.0
- Node.js >= 18
- AWS CLI configurado
- Python 3
- Backend ALB já provisionado

## 🔧 Configuração Mínima

Edite `terraform.tfvars`:

```hcl
aws_region     = "us-east-1"
environment    = "dev"
alb_endpoint   = "http://your-alb.amazonaws.com"
jwt_secret_key = "your-secret-key-minimum-32-characters"
```

## 🚀 Comandos Essenciais

```bash
# Ver todos os comandos disponíveis
make help

# Build do Lambda
make build

# Validar configuração
make validate

# Ver plano de mudanças
make plan

# Aplicar mudanças
make apply

# Testar endpoints
make test

# Ver logs
make logs-api
make logs-lambda

# Listar endpoints
make endpoints

# Destruir recursos
make destroy
```

## 📝 Adicionar Novo Endpoint

1. Edite `openapi-spec.json`:

```json
"/seu-endpoint": {
  "get": {
    "summary": "Descrição do endpoint",
    "tags": ["categoria"],
    "security": [{ "BearerAuth": [] }],
    "responses": {
      "200": { "description": "Success" }
    },
    "x-amazon-apigateway-integration": {
      "type": "http_proxy",
      "httpMethod": "GET",
      "uri": "${alb_endpoint}/seu-endpoint",
      "passthroughBehavior": "when_no_match",
      "requestParameters": {
        "integration.request.header.Authorization": "method.request.header.Authorization"
      }
    }
  }
}
```

2. Deploy:

```bash
make apply
```

Pronto! ✅

## 🧪 Testar API

### Endpoint Público

```bash
curl -X POST https://your-api.execute-api.us-east-1.amazonaws.com/dev/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### Endpoint Protegido

```bash
# 1. Obter token
TOKEN=$(curl -X POST https://your-api.../dev/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}' \
  | jq -r '.token')

# 2. Usar token
curl -X GET https://your-api.../dev/users \
  -H "Authorization: Bearer $TOKEN"
```

## 📊 Estrutura do OpenAPI

```json
{
  "openapi": "3.0.0",
  "info": { ... },
  "servers": [ ... ],
  "components": {
    "securitySchemes": {
      "BearerAuth": { ... }
    }
  },
  "paths": {
    "/endpoint": {
      "method": {
        "summary": "...",
        "security": [ ... ],
        "x-amazon-apigateway-integration": { ... }
      }
    }
  }
}
```

## 🔐 Tipos de Endpoint

### Público (sem autenticação)

```json
{
  "post": {
    "summary": "Public endpoint",
    "x-amazon-apigateway-integration": {
      "type": "http_proxy",
      "httpMethod": "POST",
      "uri": "${alb_endpoint}/path"
    }
  }
}
```

### Protegido (requer JWT)

```json
{
  "get": {
    "summary": "Protected endpoint",
    "security": [{ "BearerAuth": [] }],
    "x-amazon-apigateway-integration": {
      "type": "http_proxy",
      "httpMethod": "GET",
      "uri": "${alb_endpoint}/path",
      "requestParameters": {
        "integration.request.header.Authorization": "method.request.header.Authorization"
      }
    }
  }
}
```

### Com Path Parameter

```json
{
  "/users/{id}": {
    "get": {
      "summary": "Get user by ID",
      "security": [{ "BearerAuth": [] }],
      "parameters": [
        {
          "name": "id",
          "in": "path",
          "required": true,
          "schema": { "type": "string" }
        }
      ],
      "x-amazon-apigateway-integration": {
        "type": "http_proxy",
        "httpMethod": "GET",
        "uri": "${alb_endpoint}/users/{id}",
        "requestParameters": {
          "integration.request.path.id": "method.request.path.id",
          "integration.request.header.Authorization": "method.request.header.Authorization"
        }
      }
    }
  }
}
```

### Com Query Parameter

```json
{
  "/users": {
    "get": {
      "summary": "List users",
      "security": [{ "BearerAuth": [] }],
      "parameters": [
        {
          "name": "role",
          "in": "query",
          "required": false,
          "schema": { "type": "string" }
        }
      ],
      "x-amazon-apigateway-integration": {
        "type": "http_proxy",
        "httpMethod": "GET",
        "uri": "${alb_endpoint}/users",
        "requestParameters": {
          "integration.request.header.Authorization": "method.request.header.Authorization"
        }
      }
    }
  }
}
```

## 🐛 Troubleshooting Rápido

### Lambda não funciona

```bash
make logs-lambda
cd lambda && npm install && cd ..
make build && make apply
```

### API retorna 403

```bash
# Verificar token
echo $TOKEN | cut -d'.' -f2 | base64 -d | jq

# Verificar logs
make logs-lambda
```

### Mudanças não aplicadas

```bash
make taint-deployment
make apply
```

### Validar OpenAPI

```bash
python3 -m json.tool openapi-spec.json
```

## 📚 Documentação Completa

- [README.md](README.md) - Documentação principal
- [ARCHITECTURE.md](ARCHITECTURE.md) - Arquitetura detalhada
- [DEPLOYMENT.md](DEPLOYMENT.md) - Guia de deployment
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Estrutura do projeto
- [INTEGRATION.md](INTEGRATION.md) - Integração com infraestrutura
- [ENDPOINTS.md](ENDPOINTS.md) - Referência de endpoints
- [openapi/README.md](openapi/README.md) - Guia da estrutura modular
- [CHANGELOG.md](CHANGELOG.md) - Histórico de mudanças

## 💡 Dicas

1. **Sempre valide antes de aplicar**: `make validate`
2. **Use o Makefile**: Comandos padronizados e seguros
3. **Teste localmente**: Use o script `test-endpoints.sh`
4. **Monitore logs**: `make logs-api` e `make logs-lambda`
5. **Documente mudanças**: Mantenha CHANGELOG atualizado

## 🎯 Próximos Passos

Depois do setup inicial:

1. Familiarize-se com o OpenAPI spec
2. Adicione seus próprios endpoints
3. Configure monitoramento
4. Implemente testes automatizados
5. Configure CI/CD

## 🆘 Ajuda

```bash
# Ver comandos disponíveis
make help

# Ver outputs do Terraform
make output

# Ver estado dos recursos
make state

# Estimar custos
make cost-estimate
```

## 📞 Suporte

- Documentação: Veja arquivos `.md` no diretório
- Issues: Abra uma issue no repositório
- Logs: `make logs-api` ou `make logs-lambda`

---

**Tempo total de setup: ~5 minutos** ⚡

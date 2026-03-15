# Estrutura do Projeto - API Gateway

## Visão Geral

Este projeto implementa um API Gateway usando **OpenAPI 3.0 como fonte única de verdade**. A especificação OpenAPI é modular, organizada em arquivos separados por domínio, e consolidada automaticamente durante o build.

## Estrutura de Diretórios

```
api-gateway/
│
├── README.md                      # Documentação principal
├── ARCHITECTURE.md                # Arquitetura e fluxo de requisições
├── DEPLOYMENT.md                  # Guia de deployment
├── INTEGRATION.md                 # Integração com infraestrutura
├── ENDPOINTS.md                   # Referência de endpoints
├── PROJECT_STRUCTURE.md           # Este arquivo
├── QUICK_START.md                 # Setup rápido (5 minutos)
├── CHANGELOG.md                   # Histórico de mudanças
│
├── .gitignore                     # Arquivos ignorados pelo Git
├── Makefile                       # Comandos de build e deploy
│
├── main.tf                        # Configuração principal Terraform
├── authorizer.tf                  # Lambda authorizer JWT
├── variables.tf                   # Variáveis de entrada
├── outputs.tf                     # Outputs do Terraform
├── terraform.tfvars.example       # Exemplo de configuração
│
├── openapi-spec.json              # ⭐ Gerado automaticamente
│
├── openapi/                       # ⭐ Definições modulares (fonte)
│   ├── README.md                 # Guia da estrutura modular
│   ├── base.json                 # Configuração base
│   └── paths/                    # Endpoints por módulo
│       ├── auth.json
│       ├── users.json
│       ├── customers.json
│       ├── vehicles.json
│       ├── services.json
│       ├── products.json
│       ├── inventory.json
│       └── service-orders.json
│
├── lambda/                        # Lambda authorizer
│   ├── .gitignore
│   ├── README.md
│   ├── package.json               # Dependências Node.js
│   ├── index.js                   # Lógica de validação JWT
│   └── authorizer.zip             # Pacote de deploy (gerado)
│
└── scripts/                       # Scripts utilitários
    ├── build.sh                   # Build do Lambda
    ├── build-openapi.py           # Consolidação do OpenAPI modular
    └── test-endpoints.sh          # Testes automatizados
```

## Arquivos Principais

### Terraform

#### `main.tf`

Configuração principal que:

- Lê o `openapi-spec.json`
- Substitui variáveis (ALB endpoint, authorizer ARN)
- Cria o API Gateway REST API
- Configura deployment, stage, logs e métricas

#### `authorizer.tf`

Define:

- Lambda function para validação JWT
- IAM roles e policies
- API Gateway authorizer
- Permissões de invocação

#### `variables.tf`

Variáveis configuráveis:

- `aws_region`: Região AWS
- `environment`: Ambiente (dev/staging/prod)
- `alb_endpoint`: URL do backend ALB
- `jwt_secret_key`: Chave secreta JWT
- `stage_name`: Nome do stage
- `throttle_*`: Configurações de throttling
- `log_retention_days`: Retenção de logs

#### `outputs.tf`

Exporta:

- URL da API
- IDs de recursos
- ARNs para integração

### OpenAPI Specification

#### `openapi-spec.json`

**Fonte única de verdade** que define:

1. **Metadata da API**
   - Título, versão, descrição
   - Informações de contato

2. **Servidores**
   - Backend ALB endpoint (variável)

3. **Segurança**
   - Esquema BearerAuth
   - Configuração do Lambda authorizer

4. **Validadores**
   - Validação de request body
   - Validação de parâmetros

5. **Gateway Responses**
   - CORS headers para 4xx/5xx

6. **Paths (30+ endpoints)**
   - Definição de cada endpoint
   - Métodos HTTP
   - Parâmetros e schemas
   - Integrações com backend
   - Configurações de segurança

### Lambda Authorizer

#### `lambda/index.js`

Implementa:

- Validação de token JWT
- Extração de claims (user_id, role)
- Geração de IAM policy (Allow/Deny)
- Cache de autorização (5 minutos)

#### `lambda/package.json`

Dependências:

- `jsonwebtoken`: Validação JWT

### Scripts

#### `scripts/build.sh`

- Valida pré-requisitos (Node.js, npm)
- Instala dependências do Lambda
- Cria pacote ZIP para deploy
- Valida sintaxe do Terraform

#### `scripts/generate-openapi.py`

Script Python opcional para gerar OpenAPI spec a partir de definições estruturadas.

#### `scripts/test-endpoints.sh`

Testa todos os endpoints:

- Endpoints públicos
- Endpoints protegidos (com JWT)
- Validação de respostas

## Fluxo de Dados

### 1. Definição da API

```
openapi-spec.json
    ↓
Terraform lê e processa
    ↓
Substitui variáveis (${alb_endpoint}, ${authorizer_arn})
    ↓
Cria API Gateway REST API
```

### 2. Request Flow

```
Cliente
    ↓
API Gateway
    ↓
Lambda Authorizer (se protegido)
    ↓
Backend ALB
    ↓
Aplicação Go
```

### 3. Deploy Flow

```
1. Build Lambda (scripts/build.sh)
2. terraform init
3. terraform plan
4. terraform apply
    ↓
    ├─ Lambda Authorizer
    ├─ API Gateway (from OpenAPI)
    ├─ Stage & Deployment
    └─ CloudWatch Logs
```

## Padrões de Código

### Endpoint Público

```json
"/auth/login": {
  "post": {
    "summary": "Authenticate user",
    "tags": ["auth"],
    "responses": {
      "200": { "description": "Success" }
    },
    "x-amazon-apigateway-integration": {
      "type": "http_proxy",
      "httpMethod": "POST",
      "uri": "${alb_endpoint}/auth/login",
      "passthroughBehavior": "when_no_match"
    }
  }
}
```

### Endpoint Protegido

```json
"/users/{id}": {
  "get": {
    "summary": "Get user by ID",
    "tags": ["users"],
    "security": [{ "BearerAuth": [] }],
    "parameters": [
      {
        "name": "id",
        "in": "path",
        "required": true,
        "schema": { "type": "string" }
      }
    ],
    "responses": {
      "200": { "description": "Success" }
    },
    "x-amazon-apigateway-integration": {
      "type": "http_proxy",
      "httpMethod": "GET",
      "uri": "${alb_endpoint}/users/{id}",
      "passthroughBehavior": "when_no_match",
      "requestParameters": {
        "integration.request.path.id": "method.request.path.id",
        "integration.request.header.Authorization": "method.request.header.Authorization"
      }
    }
  }
}
```

## Recursos AWS Criados

### API Gateway

- 1x REST API
- 1x Deployment
- 1x Stage
- 30+ Methods (um por endpoint)
- 1x Authorizer (Lambda)
- 1x Account (CloudWatch role)

### Lambda

- 1x Function (JWT authorizer)
- 1x IAM Role
- 1x CloudWatch Log Group

### CloudWatch

- 1x Log Group (API Gateway)
- 1x Log Group (Lambda)
- Métricas automáticas

### IAM

- 1x Role (Lambda execution)
- 1x Role (API Gateway CloudWatch)
- 2x Policy Attachments
- 1x Lambda Permission (API Gateway invoke)

## Convenções de Nomenclatura

### Recursos Terraform

- `{service}_{resource}_{environment}`
- Exemplo: `oficina_tech_api_dev`

### Tags AWS

```hcl
{
  Project     = "oficina-tech"
  Environment = var.environment
  ManagedBy   = "terraform"
  Component   = "api-gateway"
}
```

### Endpoints OpenAPI

- Usar kebab-case: `/service-orders`
- Path parameters: `{id}`, `{product_id}`
- Query parameters: `customer_id`, `status`

## Manutenção

### Adicionar Novo Endpoint

1. Editar `openapi-spec.json`
2. Adicionar definição do path
3. Configurar integração com backend
4. Definir segurança (se necessário)
5. `terraform apply`

### Modificar Endpoint Existente

1. Localizar path em `openapi-spec.json`
2. Modificar configuração
3. `terraform apply` (redeploy automático)

### Atualizar Lambda Authorizer

1. Modificar `lambda/index.js`
2. `./scripts/build.sh`
3. `terraform apply`

### Ajustar Throttling

1. Modificar `variables.tf` ou `terraform.tfvars`
2. `terraform apply`

## Backup e Versionamento

### Código

- Todo código versionado no Git
- OpenAPI spec é código (Infrastructure as Code)

### Estado Terraform

- Recomendado: S3 backend com versionamento
- Lock via DynamoDB

### Lambda

- Código versionado no Git
- ZIP gerado em build time

## Comparação: Antes vs Depois

### Antes (Módulos Terraform)

```
api-gateway/
├── modules/
│   ├── auth/main.tf (100 linhas)
│   ├── users/main.tf (200 linhas)
│   ├── customers/main.tf (250 linhas)
│   ├── vehicles/main.tf (200 linhas)
│   ├── services/main.tf (200 linhas)
│   ├── products/main.tf (150 linhas)
│   └── service_orders/main.tf (300 linhas)
├── main.tf (150 linhas)
└── cors.tf (100 linhas)

Total: ~1,650 linhas de Terraform
```

### Depois (OpenAPI)

```
api-gateway/
├── openapi-spec.json (1,880 linhas - mas é JSON estruturado)
├── main.tf (150 linhas)
└── authorizer.tf (100 linhas)

Total: ~250 linhas de Terraform
Redução: 85% menos código Terraform
```

## Benefícios da Nova Estrutura

1. **Menos Duplicação**: Código Terraform reduzido em 85%
2. **Manutenção Simples**: Um arquivo para toda a API
3. **Documentação Automática**: Swagger UI gerado do OpenAPI
4. **Validação Integrada**: Request validation no API Gateway
5. **Versionamento Claro**: Versão da API no OpenAPI spec
6. **Padrão da Indústria**: OpenAPI é amplamente adotado
7. **Ferramentas**: Muitas ferramentas suportam OpenAPI

## Próximos Passos

1. ✅ Consolidar em OpenAPI
2. ✅ Remover módulos duplicados
3. ✅ Atualizar documentação
4. ✅ Estrutura modular implementada
5. 🔄 Adicionar schemas de request/response
6. 🔄 Implementar validação de request
7. 🔄 Adicionar exemplos de request/response
8. 🔄 Gerar documentação Swagger UI
9. 🔄 Adicionar testes de contrato

## Referências

- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [AWS API Gateway OpenAPI Extensions](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html)
- [Terraform AWS API Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api)

## Documentação Relacionada

- [README.md](README.md) - Documentação principal
- [ARCHITECTURE.md](ARCHITECTURE.md) - Arquitetura detalhada
- [QUICK_START.md](QUICK_START.md) - Setup rápido
- [openapi/README.md](openapi/README.md) - Guia da estrutura modular

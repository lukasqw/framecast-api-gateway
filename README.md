# API Gateway - Oficina Tech

API Gateway gerenciado via OpenAPI Specification para o sistema de gestão de oficina automotiva.

## Arquitetura

Este API Gateway usa **OpenAPI 3.0** como fonte única de verdade para definir todos os endpoints, integrações e configurações de segurança. A infraestrutura é provisionada via Terraform.

### Componentes

- **OpenAPI Spec** (`openapi-spec.json`): Define todos os 30+ endpoints da API
- **Lambda Authorizer**: Valida tokens JWT para endpoints protegidos
- **Lambda CPF Auth**: Autentica clientes/usuários via CPF e gera tokens JWT
- **API Gateway**: Proxy HTTP para o backend ALB
- **CloudWatch**: Logs e métricas

## Estrutura do Projeto

```
├── README.md                  # Este arquivo
├── Makefile                   # Comandos de build e deploy
│
├── main.tf                    # Configuração principal do Terraform
├── authorizer.tf              # Lambda authorizer JWT
├── auth-lambda.tf             # Lambda autenticação via CPF
├── variables.tf               # Variáveis de entrada
├── outputs.tf                 # Outputs do Terraform
├── terraform.tfvars.example   # Exemplo de configuração
│
├── openapi-spec.json          # Especificação OpenAPI (gerado)
├── openapi/                   # ⭐ Definições OpenAPI modulares
│   ├── README.md             # Guia da estrutura modular
│   ├── base.json             # Configuração base
│   └── paths/                # Endpoints por módulo
│       ├── auth.json
│       ├── users.json
│       ├── customers.json
│       ├── vehicles.json
│       ├── services.json
│       ├── products.json
│       ├── inventory.json
│       └── service-orders.json
│
├── lambda/                    # Lambda functions
│   ├── index.js              # Authorizer - Validação JWT
│   ├── package.json          # Dependências do authorizer
│   ├── README.md             # Documentação do authorizer
│   └── auth/                 # ⭐ Lambda de autenticação via CPF
│       ├── index.js          # Autenticação CPF + geração JWT
│       ├── package.json      # Dependências (pg, bcryptjs, jwt)
│       └── README.md         # Documentação completa
│
├── scripts/                   # Scripts de automação
│   ├── build-openapi.py      # Build do OpenAPI modular
│   ├── test-endpoints.sh     # Testes de endpoints
│   └── test-auth.sh          # ⭐ Testes de autenticação via CPF
│
└── docs/                      # Documentação detalhada
    ├── QUICK_START.md        # Guia rápido
    ├── ARCHITECTURE.md       # Arquitetura detalhada
    ├── DEPLOYMENT.md         # Guia de deploy
    ├── INTEGRATION.md        # Integração com backend
    ├── ENDPOINTS.md          # Referência de endpoints
    ├── PROJECT_STRUCTURE.md  # Estrutura do projeto
    └── CHANGELOG.md          # Histórico de mudanças
│
└── docs/                      # 📚 Documentação
    ├── ARCHITECTURE.md       # Arquitetura detalhada
    ├── DEPLOYMENT.md         # Guia de deployment
    ├── INTEGRATION.md        # Integração com infraestrutura
    ├── ENDPOINTS.md          # Referência de endpoints
    ├── PROJECT_STRUCTURE.md  # Estrutura do projeto
    ├── QUICK_START.md        # Setup rápido (5 minutos)
    └── CHANGELOG.md          # Histórico de mudanças
```

## Vantagens do OpenAPI Modular

1. **Estrutura Modular**: Endpoints organizados por módulo em arquivos separados
2. **Fonte Única de Verdade**: Especificação consolidada automaticamente
3. **Documentação Automática**: Swagger UI gerado automaticamente
4. **Validação de Request**: Validação automática de parâmetros e body
5. **Menos Código**: Elimina centenas de linhas de Terraform duplicado
6. **Fácil Manutenção**: Adicionar/modificar endpoints é simples e rápido
7. **Colaboração**: Múltiplos desenvolvedores podem trabalhar simultaneamente
8. **Versionamento**: Controle de versão da API integrado

## Endpoints

A API expõe 30+ endpoints organizados por módulos:

- **Auth** (1): Login de usuários
- **Users** (3): CRUD de usuários (ADMIN)
- **Customers** (4): CRUD de clientes
- **Vehicles** (4): CRUD de veículos
- **Services** (4): Catálogo de serviços
- **Products** (3): CRUD de produtos
- **Inventory** (7): Gestão de estoque
- **Service Orders** (6): Ordens de serviço

Ver `ENDPOINTS.md` para detalhes completos.

## Deploy

### Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado
- Node.js 18+ (para Lambda)
- Python 3.11+ (para build do OpenAPI)
- Backend ALB já provisionado

### Passos

1. **Build do OpenAPI Spec** ⚠️ **OBRIGATÓRIO**

```bash
# Sempre executar antes do Terraform
make build-openapi
# ou
python scripts/build-openapi.py
```

2. **Build do Lambda Authorizer**

```bash
cd lambda
npm install
cd ..
./scripts/build.sh
```

3. **Configurar Variáveis**

```bash
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com seus valores
```

4. **Deploy**

```bash
terraform init
terraform plan
terraform apply
```

### ⚠️ Checklist Antes do Deploy

- [ ] Executou `make build-openapi` ou `python scripts/build-openapi.py`
- [ ] Arquivo `openapi-spec.json` existe na raiz do projeto
- [ ] Arquivos `lambda/authorizer.zip` e `lambda/auth.zip` existem
- [ ] Arquivo `terraform.tfvars` configurado com valores corretos
- [ ] AWS CLI configurado com credenciais válidas

### Variáveis Obrigatórias

```hcl
aws_region      = "us-east-1"
environment     = "production"
alb_endpoint    = "http://your-alb-endpoint.com"
jwt_secret      = "your-jwt-secret-key-32-chars-min"
db_password     = "your-database-password"
```

## Modificar a API

### Adicionar Novo Endpoint

Edite `openapi-spec.json`:

```json
"/new-endpoint": {
  "get": {
    "summary": "Description",
    "tags": ["module"],
    "security": [{ "BearerAuth": [] }],
    "responses": {
      "200": { "description": "Success" }
    },
    "x-amazon-apigateway-integration": {
      "type": "http_proxy",
      "httpMethod": "GET",
      "uri": "${alb_endpoint}/new-endpoint",
      "passthroughBehavior": "when_no_match",
      "requestParameters": {
        "integration.request.header.Authorization": "method.request.header.Authorization"
      }
    }
  }
}
```

Depois execute:

```bash
terraform apply
```

### Endpoint Público vs Protegido

**Público** (sem autenticação):

```json
{
  "post": {
    "summary": "Public endpoint",
    "responses": { "200": { "description": "Success" } },
    "x-amazon-apigateway-integration": {
      "type": "http_proxy",
      "httpMethod": "POST",
      "uri": "${alb_endpoint}/path"
    }
  }
}
```

**Protegido** (requer JWT):

```json
{
  "get": {
    "summary": "Protected endpoint",
    "security": [{ "BearerAuth": [] }],
    "responses": { "200": { "description": "Success" } },
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

## Testes

```bash
# Testar todos os endpoints
./scripts/test-endpoints.sh

# Testar endpoint específico
curl -X POST https://your-api-gateway.com/dev/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'
```

## Monitoramento

- **CloudWatch Logs**: `/aws/apigateway/oficina-tech-{env}`
- **CloudWatch Metrics**: API Gateway dashboard
- **X-Ray Tracing**: Habilitado para rastreamento distribuído

## Custos

Estimativa mensal (ambiente dev):

- API Gateway: ~$3.50/milhão de requests
- Lambda Authorizer: ~$0.20/milhão de invocações
- CloudWatch Logs: ~$0.50/GB
- Total estimado: < $10/mês para tráfego baixo

## Troubleshooting

### Lambda Authorizer Falha

```bash
# Ver logs do Lambda
aws logs tail /aws/lambda/oficina-tech-jwt-authorizer-dev --follow
```

### API Gateway 403

- Verificar se o token JWT está válido
- Verificar se o Lambda authorizer tem permissões corretas
- Verificar logs do CloudWatch

### Mudanças no OpenAPI não aplicadas

```bash
# Forçar redeploy
terraform taint aws_api_gateway_deployment.oficina_tech
terraform apply
```

## Documentação

Toda a documentação está organizada na pasta `docs/`:

- [STRUCTURE.md](STRUCTURE.md) - Visão geral da estrutura do projeto 📁
- [QUICK_START.md](docs/QUICK_START.md) - Setup rápido (5 minutos) ⚡
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Arquitetura detalhada e fluxo de requisições
- [DEPLOYMENT.md](docs/DEPLOYMENT.md) - Guia de deployment completo
- [INTEGRATION.md](docs/INTEGRATION.md) - Integração com infraestrutura existente
- [ENDPOINTS.md](docs/ENDPOINTS.md) - Referência completa de endpoints
- [PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) - Estrutura detalhada do projeto
- [CHANGELOG.md](docs/CHANGELOG.md) - Histórico de mudanças

Documentação da estrutura modular:

- [openapi/README.md](openapi/README.md) - Guia da estrutura modular do OpenAPI

## Comandos Úteis

```bash
make help          # Ver todos os comandos disponíveis
make setup         # Setup inicial completo
make build         # Build OpenAPI + Lambda
make validate      # Validar configuração
make plan          # Ver mudanças planejadas
make apply         # Deploy
make test          # Testar endpoints
make logs-api      # Ver logs do API Gateway
make logs-lambda   # Ver logs do Lambda
make endpoints     # Listar todos os endpoints
```

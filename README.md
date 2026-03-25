# Oficina Tech - API Gateway

API Gateway profissional para AWS com autenticação JWT, rate limiting, monitoramento e integração com backend EKS.

## Descrição

Este repositório contém a infraestrutura como código (IaC) para provisionar e gerenciar o AWS API Gateway do sistema Oficina Tech. O API Gateway atua como ponto de entrada único para todas as requisições, fornecendo autenticação JWT baseada em CPF, validação de requisições, rate limiting, cache e monitoramento completo.

A arquitetura utiliza AWS API Gateway REST API (regional) com especificação OpenAPI 3.0 modular, Lambda functions para autenticação customizada, e integração HTTP proxy com o backend rodando em EKS. Toda a infraestrutura é provisionada via Terraform com pipelines CI/CD automatizados.

## Estrutura de Pastas

```
oficina-tech-api-gateway/
├── .github/
│   └── workflows/              # Pipelines CI/CD
│       ├── ci.yml              # Validação e testes
│       └── deploy.yml          # Deploy automatizado
├── docs/
│   └── api-gateway-component-diagram.puml  # Diagrama de arquitetura
├── lambda/
│   ├── auth/                   # Lambda de autenticação CPF
│   │   ├── index.js            # Handler principal
│   │   ├── utils.js            # Funções utilitárias
│   │   └── package.json        # Dependências Node.js
│   ├── authorizer/             # Lambda authorizer JWT
│   │   └── index.js            # Validação de tokens
│   ├── package.json            # Dependências compartilhadas
│   └── auth.zip                # Pacote Lambda (gerado)
├── openapi/
│   ├── paths/                  # Definições de endpoints
│   │   ├── auth.json           # Rotas de autenticação
│   │   ├── customers.json      # Rotas de clientes
│   │   ├── vehicles.json       # Rotas de veículos
│   │   └── service-orders.json # Rotas de ordens de serviço
│   ├── paths-improved/         # Versão melhorada dos paths
│   └── base.json               # Base OpenAPI com components
├── scripts/
│   ├── build-openapi-consolidated.py  # Build da spec OpenAPI
│   ├── test-auth.sh            # Testes de autenticação
│   └── test-endpoints.sh       # Testes de endpoints
├── terraform/
│   ├── environments/           # Configurações por ambiente
│   └── modules/                # Módulos Terraform reutilizáveis
│       ├── api-gateway/        # Módulo do API Gateway
│       └── lambda/             # Módulo Lambda
├── main.tf                     # Configuração principal
├── variables.tf                # Variáveis de entrada
├── outputs.tf                  # Outputs do Terraform
├── data-sources.tf             # Data sources e locals
├── monitoring.tf               # CloudWatch alarms e logs
├── openapi-spec.json           # Spec OpenAPI consolidada (gerada)
├── openapi-template.json       # Template OpenAPI
├── terraform.tfvars.example    # Exemplo de variáveis
├── Makefile                    # Comandos automatizados
└── README.md
```

## Funcionalidades

### Segurança

- **Autenticação JWT**: Sistema de autenticação baseado em CPF via Lambda function
- **Validação de Requisições**: Validação automática de body e parameters usando OpenAPI schemas
- **CORS**: Configuração completa de CORS para acesso cross-origin
- **Rate Limiting**: Proteção contra abuso com burst limit de 5000 e rate de 10000 req/s
- **API Keys**: Suporte opcional para camada adicional de segurança
- **SSL/TLS**: Criptografia end-to-end com suporte a custom domains

### Performance

- **Cache**: Cache configurável (0.5GB) com TTL de 300 segundos
- **Connection Pooling**: Pool de conexões PostgreSQL otimizado na Lambda
- **Timeouts**: Timeouts configurados (30s Lambda, otimizados por endpoint)
- **Compressão**: Compressão automática de respostas

### Monitoramento e Observabilidade

- **CloudWatch Logs**: Logs estruturados do API Gateway e Lambda functions
- **Métricas Detalhadas**: Count, latency, 4XX/5XX errors, cache hits/misses
- **Alarmes Automáticos**:
  - 5XX Errors: Alerta quando > 10 erros em 5 minutos
  - 4XX Errors: Alerta quando > 100 erros em 5 minutos
  - Latency: Alerta quando latência média > 5 segundos
- **X-Ray Tracing**: Rastreamento distribuído de requisições (opcional)
- **Usage Plans**: Controle de quotas e throttling por cliente

### Arquitetura e Integração

- **OpenAPI 3.0 Modular**: Especificação dividida em múltiplos arquivos para manutenibilidade
- **Componentes Reutilizáveis**: Schemas, responses, parameters e security schemes compartilhados
- **Lambda Proxy Integration**: Autenticação CPF customizada com acesso ao RDS PostgreSQL
- **HTTP Proxy Integration**: Integração transparente com backend EKS via ALB
- **VPC Integration**: Lambda functions rodando dentro da VPC para acesso seguro ao RDS
- **Multi-Environment**: Suporte para múltiplos ambientes (dev, staging, production)

### CI/CD

- **Validação Automática**: Terraform validate, OpenAPI validation, Lambda build
- **Security Scanning**: Trivy scan para vulnerabilidades
- **Deploy Automatizado**: Deploy automático via GitHub Actions
- **Health Checks**: Verificação pós-deploy da saúde da API

## Tecnologias Usadas

- **Terraform** (>= 1.0): Infraestrutura como código
- **AWS API Gateway**: REST API regional com OpenAPI 3.0
- **AWS Lambda**: Node.js 20.x para autenticação customizada
- **AWS CloudWatch**: Logs, métricas e alarmes
- **AWS VPC**: Networking e security groups
- **AWS RDS**: PostgreSQL para dados de usuários
- **OpenAPI 3.0**: Especificação de API modular
- **Node.js** (>= 20.x): Runtime das Lambda functions
- **Python** (>= 3.x): Scripts de build e automação
- **GitHub Actions**: CI/CD pipelines
- **Make**: Automação de comandos

### Dependências Node.js

- **jsonwebtoken**: Geração e validação de tokens JWT
- **bcrypt**: Hash e verificação de senhas
- **pg**: Cliente PostgreSQL com connection pooling

### Recursos AWS

- AWS API Gateway (REST API)
- AWS Lambda
- AWS CloudWatch (Logs, Metrics, Alarms)
- AWS VPC (Subnets, Security Groups, ENIs)
- AWS RDS (PostgreSQL)
- AWS IAM (Roles, Policies)
- AWS S3 (Terraform state backend)
- AWS ACM (Certificados SSL - opcional)

## Como Rodar o Projeto

### Pré-requisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Python](https://www.python.org/downloads/) >= 3.x
- [Node.js](https://nodejs.org/) >= 20.x
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- Make (opcional, mas recomendado)
- Acesso ao remote state do projeto `oficina-tech-infra`
- Acesso ao remote state do projeto `oficina-tech-db`

### Configuração Inicial

1. Clone o repositório:

```bash
git clone <repository-url>
cd oficina-tech-api-gateway
```

2. Configure as credenciais AWS:

```bash
aws configure
```

3. Crie um arquivo de variáveis (não commitado):

```bash
cp terraform.tfvars.example terraform.tfvars
```

4. Edite o arquivo `terraform.tfvars` com seus valores:

```hcl
# Obrigatórias
jwt_secret  = "seu-jwt-secret-super-seguro-min-32-chars"
db_password = "sua-senha-db-segura"

# Opcionais (com valores padrão)
environment              = "dev"
stage_name              = "v1"
throttle_burst_limit    = 5000
throttle_rate_limit     = 10000
quota_limit             = 1000000
enable_logging          = true
enable_cache            = false
enable_api_key          = false
```

### Build e Deploy

#### Usando Makefile (Recomendado)

```bash
# 1. Verificar dependências
make check-deps

# 2. Build dos artefatos (Lambda + OpenAPI)
make build

# 3. Inicializar Terraform
make init

# 4. Validar configuração
make validate

# 5. Planejar mudanças
make plan

# 6. Aplicar mudanças
make apply

# Ou tudo de uma vez:
make apply-auto
```

#### Usando Terraform Diretamente

```bash
# 1. Build manual dos artefatos
cd lambda/auth
npm install --production
zip -r ../auth.zip index.js utils.js node_modules/
cd ../..

python3 scripts/build-openapi-consolidated.py

# 2. Terraform workflow
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### Obter Informações da API

```bash
# Ver todos os outputs
make outputs

# Ou com Terraform
terraform output

# Outputs importantes:
# - api_gateway_url: URL base da API
# - api_gateway_id: ID do API Gateway
# - lambda_auth_function_name: Nome da Lambda de autenticação
# - api_key_value: API Key (se habilitado)
```

### Testar a API

#### Teste de Autenticação

```bash
# Obter URL da API
API_URL=$(terraform output -raw api_gateway_url)

# Fazer login
curl -X POST $API_URL/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "cpf": "12345678901",
    "password": "senha123",
    "type": "customer"
  }'

# Resposta esperada:
# {
#   "data": {
#     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#     "user": {
#       "id": "uuid",
#       "name": "João Silva",
#       "email": "joao@example.com",
#       "cpf": "12345678901",
#       "role": "CUSTOMER"
#     }
#   }
# }
```

#### Teste de Endpoints Protegidos

```bash
# Salvar o token
TOKEN="seu-token-jwt-aqui"

# Testar endpoint protegido
curl -X GET $API_URL/customers \
  -H "Authorization: Bearer $TOKEN"

# Validar token
curl -X POST $API_URL/auth/validate \
  -H "Authorization: Bearer $TOKEN"
```

#### Scripts de Teste Automatizados

```bash
# Executar todos os testes
make test

# Ou individualmente
bash scripts/test-auth.sh
bash scripts/test-endpoints.sh
```

### Configuração Avançada

#### Rate Limiting e Throttling

```hcl
# terraform.tfvars
throttle_burst_limit = 5000    # Burst máximo
throttle_rate_limit  = 10000   # Requests por segundo
quota_limit          = 1000000 # Limite diário
```

#### Logging e Monitoramento

```hcl
enable_logging       = true
log_retention_days   = 7
enable_alarms        = true
error_threshold_5xx  = 10
error_threshold_4xx  = 100
latency_threshold_ms = 5000
```

#### Cache

```hcl
enable_cache        = true
cache_cluster_size  = "0.5"  # GB (0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237)
cache_ttl_seconds   = 300    # 5 minutos
```

#### API Key (Camada Extra de Segurança)

```hcl
enable_api_key = true
```

Após deploy, obter a chave:

```bash
terraform output api_key_value
```

Usar em requisições:

```bash
curl -X GET $API_URL/customers \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-api-key: sua-api-key"
```

#### Custom Domain

```hcl
custom_domain_name = "api.oficinatech.com"
certificate_arn    = "arn:aws:acm:us-east-1:123456789:certificate/..."
base_path          = "v1"
```

### Comandos Úteis

```bash
make help          # Mostrar todos os comandos disponíveis
make check-deps    # Verificar dependências instaladas
make build         # Build Lambda packages e OpenAPI spec
make init          # Inicializar Terraform
make validate      # Validar configuração Terraform
make format        # Formatar código Terraform
make lint          # Lint e validação completa
make plan          # Planejar mudanças
make apply         # Aplicar mudanças
make apply-auto    # Build + Plan + Apply automaticamente
make destroy       # Destruir recursos
make clean         # Limpar artefatos de build
make test          # Executar testes
make outputs       # Mostrar outputs do Terraform
make state-list    # Listar recursos no state
make fix-state     # Corrigir problemas de state
make upgrade       # Atualizar providers Terraform
```

### Monitoramento

#### CloudWatch Logs

```bash
# Ver logs da Lambda de autenticação
aws logs tail /aws/lambda/oficina-tech-cpf-auth-dev --follow

# Ver logs do API Gateway
aws logs tail /aws/apigateway/oficina-tech-dev --follow
```

#### Métricas Disponíveis

- `4XXError`: Erros de cliente (bad request, unauthorized, etc)
- `5XXError`: Erros de servidor (internal errors)
- `Count`: Total de requisições
- `Latency`: Latência das requisições (p50, p90, p99)
- `CacheHitCount`: Número de cache hits
- `CacheMissCount`: Número de cache misses

#### Alarmes Configurados

Os seguintes alarmes são criados automaticamente quando `enable_alarms = true`:

- **5XX Errors**: Alerta quando > 10 erros em 5 minutos
- **4XX Errors**: Alerta quando > 100 erros em 5 minutos
- **Latency**: Alerta quando latência média > 5 segundos

### CI/CD via GitHub Actions

O projeto possui pipelines automatizados:

#### CI Workflow (Pull Requests)

- Validação do Terraform
- Validação da especificação OpenAPI
- Build e teste das Lambda functions
- Lint do código Lambda
- Security scan com Trivy

#### Deploy Workflow (Push para main)

- Build da especificação OpenAPI consolidada
- Package das Lambda functions
- Terraform apply
- Health checks pós-deploy

#### Secrets Necessários no GitHub

Configure os seguintes secrets no repositório:

- `AWS_ACCESS_KEY_ID`: Access key da AWS
- `AWS_SECRET_ACCESS_KEY`: Secret key da AWS
- `AWS_SESSION_TOKEN`: Session token (se aplicável)
- `JWT_SECRET`: Secret para geração de tokens JWT
- `DB_PASSWORD`: Senha do banco de dados

### Variáveis de Ambiente da Lambda

A Lambda de autenticação CPF utiliza as seguintes variáveis de ambiente:

- `JWT_SECRET`: Chave secreta para geração de tokens JWT (obrigatório, min 32 caracteres)
- `DB_HOST`: Endpoint do RDS PostgreSQL
- `DB_PORT`: Porta do banco de dados (padrão: 5432)
- `DB_USER`: Usuário do banco de dados
- `DB_PASSWORD`: Senha do banco de dados (obrigatório)
- `DB_NAME`: Nome do banco de dados
- `DB_SSL`: Habilitar SSL para conexão (true/false)
- `AWS_LAMBDA_LOG_LEVEL`: Nível de log (INFO, DEBUG, ERROR)

## Arquitetura

### Diagrama de Componentes

```
┌─────────────────┐
│  External       │
│  Clients        │
│  (Web/Mobile)   │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────────────────────────────────┐
│         AWS API Gateway (Regional)          │
│  ┌────────────────────────────────────────┐ │
│  │  • Rate Limiting (5000 burst, 10k/s)  │ │
│  │  • Request Validation (OpenAPI)       │ │
│  │  • CORS Configuration                 │ │
│  │  • Cache (0.5GB, 300s TTL)           │ │
│  │  • Usage Plans & API Keys            │ │
│  └────────────────────────────────────────┘ │
└────────┬──────────────────────┬─────────────┘
         │                      │
         │ /auth/*              │ /customers/*, /vehicles/*, etc
         ▼                      ▼
┌────────────────────┐   ┌──────────────────┐
│  Lambda Function   │   │   HTTP Proxy     │
│  (CPF Auth)        │   │   Integration    │
│  • Node.js 20.x    │   └────────┬─────────┘
│  • VPC Integration │            │
│  • JWT Generation  │            ▼
└────────┬───────────┘   ┌──────────────────┐
         │               │  Application     │
         │               │  Load Balancer   │
         ▼               └────────┬─────────┘
┌────────────────────┐            │
│  RDS PostgreSQL    │            ▼
│  • users table     │   ┌──────────────────┐
│  • customers table │   │  EKS Cluster     │
└────────────────────┘   │  (Backend API)   │
                         └──────────────────┘
```

### Fluxo de Autenticação

1. Cliente envia credenciais (CPF + senha) para `/auth/login`
2. API Gateway valida a requisição usando OpenAPI schema
3. Lambda de autenticação é invocada
4. Lambda consulta o banco de dados PostgreSQL via VPC
5. Senha é verificada usando bcrypt
6. Token JWT é gerado com validade de 24 horas
7. Token é retornado ao cliente
8. Cliente usa o token no header `Authorization: Bearer {token}` para requisições subsequentes

### Fluxo de Requisições Protegidas

1. Cliente envia requisição com token JWT no header
2. API Gateway valida o formato da requisição
3. Requisição é proxy para o ALB do EKS
4. Backend valida o token JWT
5. Backend processa a requisição e retorna resposta
6. API Gateway pode cachear a resposta (se habilitado)

## Troubleshooting

### Erro: "Unauthorized"

- Verificar se o token JWT está válido e não expirou
- Verificar se o header Authorization está correto: `Bearer {token}`
- Verificar se o JWT_SECRET está configurado corretamente na Lambda
- Verificar logs da Lambda: `aws logs tail /aws/lambda/oficina-tech-cpf-auth-dev --follow`

### Erro: "Rate Limit Exceeded" (429)

- Aguardar 60 segundos antes de tentar novamente
- Ajustar `throttle_rate_limit` e `throttle_burst_limit` se necessário
- Verificar se o cliente está fazendo requisições excessivas

### Erro: "Internal Server Error" (500)

- Verificar logs da Lambda de autenticação
- Verificar conectividade da Lambda com o RDS (security groups)
- Verificar se as variáveis de ambiente estão configuradas corretamente
- Verificar se o banco de dados está acessível

### Erro: "Bad Request" (400)

- Verificar se o body da requisição está no formato correto
- Verificar se todos os campos obrigatórios estão presentes
- Consultar a especificação OpenAPI para o formato esperado

### Deploy Falha

```bash
# Limpar state local e reinicializar
make fix-state

# Validar configuração
make validate

# Tentar novamente
make apply
```

### Lambda não Consegue Conectar ao RDS

- Verificar se a Lambda está na mesma VPC que o RDS
- Verificar security groups (Lambda SG deve ter acesso ao RDS SG na porta 5432)
- Verificar se as subnets da Lambda têm rota para o RDS
- Verificar variáveis de ambiente (DB_HOST, DB_PORT, DB_USER, DB_PASSWORD)

### OpenAPI Spec não Gera Corretamente

```bash
# Limpar e rebuildar
make clean
make build

# Verificar se o arquivo foi gerado
ls -la openapi-spec.json

# Validar JSON
python -m json.tool openapi-spec.json
```

## Documentação Adicional

- [Diagrama de Componentes](docs/api-gateway-component-diagram.puml): Arquitetura detalhada
- [Especificação OpenAPI](openapi-spec.json): Documentação completa da API
- [AWS API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Segurança

### Boas Práticas Implementadas

- Tokens JWT com expiração de 24 horas
- Senhas hasheadas com bcrypt (salt rounds: 10)
- Validação de requisições usando OpenAPI schemas
- Rate limiting e throttling configurados
- Lambda functions rodando em VPC privada
- Security groups restritivos
- Logs estruturados sem informações sensíveis
- HTTPS obrigatório

### Recomendações para Produção

- Habilitar SSL no RDS (`rds.force_ssl = 1`)
- Usar AWS Secrets Manager para JWT_SECRET e DB_PASSWORD
- Habilitar API Keys para camada adicional de segurança
- Configurar custom domain com certificado ACM
- Habilitar X-Ray tracing para debugging
- Aumentar retention de logs para 30+ dias
- Configurar alarmes com notificações SNS
- Implementar WAF para proteção adicional
- Habilitar deletion protection nos recursos críticos

## Versionamento

- API Version: v1
- OpenAPI Version: 3.0.0
- Terraform Version: >= 1.0
- AWS Provider Version: ~> 5.0
- Node.js Runtime: 20.x

## Licença

Este projeto faz parte do sistema Oficina Tech.

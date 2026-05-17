# oficina-tech-api-gateway

Ponto de entrada único da plataforma Oficina Tech. Provisiona via Terraform o AWS API Gateway REST API (regional) com Lambda de autenticação via CPF, rate limiting, cache opcional, monitoramento CloudWatch e integração HTTP proxy com os microsserviços Go rodando no EKS.

> Fluxo completo de autenticação e roteamento: [docs/architecture.md](docs/architecture.md)
> Regras de comportamento do gateway: [docs/business-rules.md](docs/business-rules.md)
> Workflows CI/CD, actions, variáveis e secrets: [.github/README.md](.github/README.md)

---

## O que este repo provisiona

Recursos criados via Terraform em `terraform/environments/production/`:

| Recurso AWS | Descrição |
|---|---|
| `aws_api_gateway_rest_api` | REST API regional `oficina-tech-api-{environment}` |
| `aws_api_gateway_deployment` | Deployment da spec OpenAPI consolidada |
| `aws_api_gateway_stage` | Stage `v1` com logging e cache configuráveis |
| `aws_api_gateway_usage_plan` | Plano com throttling e quota diária |
| `aws_api_gateway_api_key` | API Key opcional (padrão: desabilitada) |
| `aws_api_gateway_domain_name` | Domínio customizado opcional |
| `aws_lambda_function` | Lambda de autenticação CPF (`POST /auth/login`) em Node.js 20.x |
| `aws_cloudwatch_log_group` | Log group `/aws/apigateway/oficina-tech-{environment}` (retenção: 7 dias) |
| `aws_cloudwatch_metric_alarm` | Alarmes de erros 5XX, 4XX e latência (padrão: desabilitados) |
| `aws_lambda_permission` | Permissão para o API Gateway invocar a Lambda de auth |

---

## Roteamento

O API Gateway roteia requisições como HTTP proxy (`http_proxy`) com timeout de 29 segundos para os microsserviços via NLB. Cada microsserviço é acessado por NodePort fixo.

| Prefixo de rota | Microsserviço | NodePort |
|---|---|---|
| `/auth/*`, `/customers/*`, `/vehicles/*`, `/users/*` | ms-identity | 30081 |
| `/service-orders/*` | ms-order-service | 30082 |
| `/products/*`, `/services/*` | ms-workshop | 30083 |

O NLB DNS é lido automaticamente via remote state (`data.terraform_remote_state.main.outputs.nlb_dns_name`). Em caso de indisponibilidade do remote state, o fallback é `http://placeholder.elb.us-east-1.amazonaws.com`.

### Tabela completa de rotas

| Método | Rota | Autenticacao | Destino |
|--------|------|-------------|---------|
| POST | `/auth/login` | Publica | Lambda de auth (CPF) |
| POST | `/auth/validate` | BearerAuth | ms-identity:30081 |
| GET | `/customers` | BearerAuth | ms-identity:30081 |
| POST | `/customers` | BearerAuth | ms-identity:30081 |
| GET | `/customers/{id}` | BearerAuth | ms-identity:30081 |
| PUT | `/customers/{id}` | BearerAuth | ms-identity:30081 |
| DELETE | `/customers/{id}` | BearerAuth | ms-identity:30081 |
| GET | `/vehicles` | BearerAuth | ms-identity:30081 |
| POST | `/vehicles` | BearerAuth | ms-identity:30081 |
| GET | `/vehicles/{id}` | BearerAuth | ms-identity:30081 |
| PUT | `/vehicles/{id}` | BearerAuth | ms-identity:30081 |
| DELETE | `/vehicles/{id}` | BearerAuth | ms-identity:30081 |
| GET | `/users` | BearerAuth | ms-identity:30081 |
| POST | `/users` | BearerAuth | ms-identity:30081 |
| GET | `/users/{id}` | BearerAuth | ms-identity:30081 |
| PUT | `/users/{id}` | BearerAuth | ms-identity:30081 |
| DELETE | `/users/{id}` | BearerAuth | ms-identity:30081 |
| GET | `/services` | BearerAuth | ms-workshop:30083 |
| POST | `/services` | BearerAuth | ms-workshop:30083 |
| GET | `/services/{id}` | BearerAuth | ms-workshop:30083 |
| PUT | `/services/{id}` | BearerAuth | ms-workshop:30083 |
| DELETE | `/services/{id}` | BearerAuth | ms-workshop:30083 |
| GET | `/products/{id}` | BearerAuth | ms-workshop:30083 |
| POST | `/products` | BearerAuth | ms-workshop:30083 |
| PUT | `/products/{id}` | BearerAuth | ms-workshop:30083 |
| DELETE | `/products/{id}` | BearerAuth | ms-workshop:30083 |
| GET | `/products/{id}/inventory` | BearerAuth | ms-workshop:30083 |
| POST | `/products/{id}/inventory` | BearerAuth | ms-workshop:30083 |
| POST | `/products/{id}/inventory/reserve` | BearerAuth | ms-workshop:30083 |
| POST | `/products/{id}/inventory/cancel-reserved` | BearerAuth | ms-workshop:30083 |
| POST | `/products/{id}/inventory/increase` | BearerAuth | ms-workshop:30083 |
| POST | `/products/{id}/inventory/manual-decrease` | BearerAuth | ms-workshop:30083 |
| POST | `/products/{id}/inventory/reserved-decrease` | BearerAuth | ms-workshop:30083 |
| GET | `/service-orders` | BearerAuth | ms-order-service:30082 |
| POST | `/service-orders` | BearerAuth | ms-order-service:30082 |
| GET | `/service-orders/{id}` | BearerAuth | ms-order-service:30082 |
| PUT | `/service-orders/{id}` | BearerAuth | ms-order-service:30082 |

---

## Autenticacao

- Todas as rotas exceto `POST /auth/login` exigem o header `Authorization: Bearer <token>`.
- A verificacao de presenca do header e feita via `BearerAuth` (tipo `apiKey` nativo do API Gateway, declarado na spec OpenAPI). Header ausente resulta em `401` devolvido diretamente pelo gateway.
- **Nao ha Lambda Authorizer implementado.** A validacao da assinatura JWT (HS256), expiracao e RBAC e responsabilidade exclusiva do backend em cada microsservico.
- O JWT e assinado com `JWT_SECRET_KEY` compartilhada entre a Lambda de auth e os microsserviços.

### Fluxo de rota protegida

```
Cliente (Authorization: Bearer <jwt>)
  |
  v
API Gateway
  |-- Header ausente? --> 401 (gateway nativo)
  |-- Header presente --> passa adiante
         |
         v
  HTTP Proxy (timeout 29s)
         |
         v
  NLB --> EKS Pod (ms correspondente)
         |-- valida assinatura JWT (HS256)
         |-- verifica expiracao
         `-- aplica RBAC por rota
```

---

## Lambda de Autenticacao (POST /auth/login)

Unica rota com logica propria. Implementada em `lambda/auth/index.js` (Node.js 20.x).

### Fluxo de execucao

```
POST /auth/login  { cpf, password, type }
  |
  v
Lambda Auth
  |-- valida campos obrigatorios (cpf, password, type)
  |-- valida formato e digitos verificadores do CPF (modulo 11)
  |-- consulta RDS PostgreSQL (db_ms1)
  |     |-- type="user"     --> tabela users (campo cpf)
  |     `-- type="customer" --> tabela customers (campo document, document_type='CPF')
  |-- verifica deleted_at --> 403 INACTIVE_ACCOUNT
  |-- compara senha com bcryptjs
  `-- emite JWT HS256 (exp: 24h, iss: "oficina-tech", aud: "oficina-tech-api")
  |
  v
{ data: { token, user } }
```

A Lambda conecta diretamente ao RDS do ms-identity (`db_ms1`) via pool de conexao `pg` (max 10 conexoes, idle timeout 30s, connection timeout 10s). As credenciais de banco sao injetadas via variaveis de ambiente da funcao Lambda.

### Claims do JWT emitido

| Campo | Valor |
|-------|-------|
| `user_id` | UUID da entidade |
| `sub` | UUID da entidade |
| `email` | Email |
| `name` | Nome |
| `cpf` | CPF (campo `cpf` ou `document`) |
| `role` | `ADMIN`, `MANAGER`, `USER` (usuarios) ou `CUSTOMER` (clientes) |
| `type` | `"user"` ou `"customer"` |
| `iss` | `"oficina-tech"` |
| `aud` | `"oficina-tech-api"` |

### Codigos de erro da Lambda

| HTTP | Codigo | Motivo |
|------|--------|--------|
| 400 | `INVALID_CPF` | CPF com formato ou digitos verificadores invalidos |
| 400 | `MISSING_FIELDS` | Campos `cpf`, `password` ou `type` ausentes |
| 400 | `INVALID_TYPE` | `type` diferente de `"user"` ou `"customer"` |
| 401 | `INVALID_CREDENTIALS` | CPF nao encontrado ou senha incorreta |
| 403 | `INACTIVE_ACCOUNT` | Conta com soft delete ativo (`deleted_at` preenchido) |
| 500 | `INTERNAL_ERROR` | Erro no banco ou erro inesperado |

---

## Rate Limiting

Configurado via Usage Plan no modulo `api-gateway`. Valores padrao (ajustaveis por ambiente):

| Parametro | Variavel | Padrao |
|-----------|----------|--------|
| Burst (requisicoes simultaneas) | `throttle_burst_limit` | 5000 |
| Taxa (requisicoes por segundo) | `throttle_rate_limit` | 10000 |
| Quota diaria | `quota_limit` | 1000000 |

---

## Monitoramento

Alarmes CloudWatch em `monitoring.tf` — desabilitados por padrao (`enable_alarms = false`):

| Alarme | Metrica | Threshold | Janela |
|--------|---------|-----------|--------|
| Erros 5XX | `5XXError` (Sum) | 10 erros | 2x 5 min |
| Erros 4XX | `4XXError` (Sum) | 100 erros | 2x 5 min |
| Latencia | `Latency` (Average) | 5000 ms | 2x 5 min |

- Log group: `/aws/apigateway/oficina-tech-{environment}`
- Retencao de logs: 7 dias
- Logging e X-Ray: desabilitados por padrao

---

## Variaveis Terraform

Definidas em `terraform/environments/production/variables.tf`:

| Variavel | Tipo | Padrao | Descricao |
|----------|------|--------|-----------|
| `aws_region` | string | `"us-east-1"` | Regiao AWS |
| `environment` | string | `"dev"` | Nome do ambiente |
| `stage_name` | string | `"v1"` | Nome do stage do API Gateway |
| `jwt_secret` | string | — | Chave de assinatura JWT (sensivel) |
| `db_password` | string | — | Senha do banco de dados (sensivel) |
| `db_ssl_enabled` | string | `"true"` | Habilitar SSL na conexao com o banco |
| `alb_endpoint` | string | `""` | Override do endpoint do ALB/NLB (vazio = usa remote state) |
| `ms_identity_endpoint` | string | `""` | Override do endpoint ms-identity (vazio = `nlb_dns:30081`) |
| `ms_order_endpoint` | string | `""` | Override do endpoint ms-order-service (vazio = `nlb_dns:30082`) |
| `ms_workshop_endpoint` | string | `""` | Override do endpoint ms-workshop (vazio = `nlb_dns:30083`) |
| `throttle_burst_limit` | number | `5000` | Limite de burst do API Gateway |
| `throttle_rate_limit` | number | `10000` | Taxa de requisicoes por segundo |
| `quota_limit` | number | `1000000` | Quota diaria de requisicoes |
| `enable_logging` | bool | `false` | Habilitar CloudWatch Logs para o API Gateway |
| `log_retention_days` | number | `7` | Retencao de logs em dias |
| `enable_alarms` | bool | `false` | Habilitar alarmes CloudWatch |
| `error_threshold_5xx` | number | `10` | Threshold para alarme de erros 5XX |
| `error_threshold_4xx` | number | `100` | Threshold para alarme de erros 4XX |
| `latency_threshold_ms` | number | `5000` | Threshold de latencia em milissegundos |
| `enable_cache` | bool | `false` | Habilitar cache do API Gateway |
| `cache_cluster_size` | string | — | Tamanho do cluster de cache |
| `cache_ttl_seconds` | number | — | TTL do cache em segundos |
| `enable_api_key` | bool | `false` | Habilitar API Key |
| `custom_domain_name` | string | `""` | Dominio customizado (vazio = desabilitado) |
| `certificate_arn` | string | `""` | ARN do certificado ACM para dominio customizado |
| `base_path` | string | `""` | Base path para o dominio customizado |
| `lab_role` | string | `""` | ARN do IAM Role para Lambda (vazio = constroi automaticamente como `arn:aws:iam::{account_id}:role/LabRole`) |
| `lambda_subnet_ids` | list(string) | `[]` | IDs das subnets para a Lambda (vazio = usa remote state) |
| `lambda_security_group_ids` | list(string) | `[]` | Security Groups para a Lambda (vazio = usa remote state) |
| `tf_state_bucket` | string | — | Bucket S3 do Terraform state remoto |

---

## Outputs Terraform

Outputs do modulo `api-gateway` (acessiveis via `module.api_gateway.<output>`):

| Output | Descricao |
|--------|-----------|
| `rest_api_id` | ID da REST API |
| `rest_api_name` | Nome da REST API |
| `rest_api_execution_arn` | ARN de execucao do API Gateway |
| `stage_name` | Nome do stage |
| `stage_invoke_url` | URL de invocacao do stage |
| `deployment_id` | ID do deployment |
| `usage_plan_id` | ID do Usage Plan |
| `usage_plan_name` | Nome do Usage Plan |
| `api_key_id` | ID da API Key (se habilitada) |
| `api_key_value` | Valor da API Key — sensivel (se habilitada) |
| `custom_domain_name` | Dominio customizado (se configurado) |
| `custom_domain_regional_domain_name` | Regional domain name do dominio customizado |
| `custom_domain_regional_zone_id` | Zone ID regional do dominio customizado |

Outputs do modulo `lambda`:

| Output | Descricao |
|--------|-----------|
| `function_arn` | ARN da Lambda de auth |
| `function_name` | Nome da Lambda de auth |

Outputs de teste e monitoramento:

| Output | Descricao |
|--------|-----------|
| `test_auth_command` | Comando `curl` de exemplo para testar `POST /auth/login` |
| `test_customers_command` | Comando `curl` de exemplo para testar `GET /customers` |
| `api_documentation_url` | URL da documentacao OpenAPI/Swagger |

---

## Dependencias de Remote State

O arquivo `terraform/environments/production/data-sources.tf` le dois remote states do S3:

### oficina-tech-infra (`fiap/infra/terraform.tfstate`)

| Output consumido | Uso no api-gateway |
|---|---|
| `nlb_dns_name` | DNS do NLB para construir os endpoints dos microsservicos |
| `subnet_ids` | Subnets para a Lambda de auth (se `lambda_subnet_ids` nao for informado) |
| `eks_security_group_id` | Security group para a Lambda de auth (se `lambda_security_group_ids` nao for informado) |

### oficina-tech-db (`fiap/db/terraform.tfstate`)

| Output consumido | Uso no api-gateway |
|---|---|
| `rds_ms1_address` | Host do PostgreSQL para a Lambda de auth |
| `rds_ms1_port` | Porta do PostgreSQL |
| `rds_ms1_database_name` | Nome do banco (`db_ms1`) |
| `rds_ms1_username` | Usuario do banco |

---

## Como fazer deploy

### Pre-requisitos

- Terraform >= 1.7.0
- AWS CLI configurado com credenciais validas (ou variaveis de ambiente `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`)
- Bucket S3 para o Terraform state ja criado
- Remote states de `oficina-tech-infra` e `oficina-tech-db` aplicados previamente
- `lambda/auth.zip` gerado (`npm ci --production` na pasta `lambda/auth/` + zip)
- `openapi-spec.json` gerado (`python scripts/build-openapi-consolidated.py`)

### Passos

```bash
cd terraform/environments/production

# Cria o arquivo de variaveis a partir do exemplo
cp ../../../terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com jwt_secret, db_password e tf_state_bucket

# Inicializar backend S3
terraform init \
  -backend-config="bucket=<TF_STATE_BUCKET>" \
  -backend-config="region=us-east-1"

# Visualizar mudancas
terraform plan

# Aplicar
terraform apply
```

Apos o apply, a URL do API Gateway e exibida no output `stage_invoke_url`.

---

## CI/CD

O pipeline e descrito em detalhe em [.github/README.md](.github/README.md). Resumo:

| Workflow | Trigger | O que faz |
|---|---|---|
| `ci.yml` | PR para `develop`/`main`; push em `develop` | fmt check, `terraform validate`, tfsec + Checkov, `terraform plan`, validacao de estrutura de modulos, qualidade da Lambda |
| `release.yml` | Push em `develop` (paths: `terraform/**`, `lambda/**`, `openapi/**`, `scripts/**`) | Calcula versao por Conventional Commits e cria/atualiza PR de release |
| `deploy.yml` | PR `release/*` mergeado em `main`; `workflow_dispatch` | Build artefatos (OpenAPI + Lambda zip) → `terraform apply` → health check no API Gateway (5x, 30s) → testes de integracao → cria tag e GitHub Release |
| `rollback.yml` | `workflow_dispatch` (versao + ambiente) | Rebuild artefatos da tag informada + `terraform apply`; sem criar nova tag |
| `destroy.yml` | `workflow_dispatch` (confirmacao manual) | Build artefatos + `terraform destroy` |

### Composite Actions

```
.github/actions/
├── build/
│   ├── openapi/     Python + build-openapi-consolidated.py → openapi-spec.json
│   └── lambda/      npm ci --production + zip → lambda/auth.zip
├── ci/
│   ├── tf-validate/ fmt check + terraform init (sem backend) + validate
│   ├── tf-security/ tfsec + Checkov + upload SARIF para GitHub Security
│   ├── tf-plan/     terraform plan + upload artifact + comentario no PR
│   └── tf-structure verifica arquivos obrigatorios e estrutura de modulos
├── release/
│   ├── create-pr/   calcula versao, cria branch e draft PR
│   └── update-pr/   sincroniza branch de release com develop e atualiza changelog
└── deploy/
    ├── tf-apply/    init + apply + exporta URL e ID do API Gateway
    ├── api-check/   probe HTTP no API Gateway com retry (5x, 30s)
    └── create-release/ git tag anotada + GitHub Release com links e endpoint
```

### Versionamento

- `feat:` → minor bump
- `feat!:` → major bump
- Demais tipos (`fix:`, `chore:`, `refactor:`, etc.) → patch bump
- Tag criada somente apos o health check confirmar o deploy em producao

### Variaveis e Secrets obrigatorios no repositorio GitHub

| Nome | Tipo | Descricao |
|------|------|-----------|
| `TF_STATE_BUCKET` | Variable | Bucket S3 do Terraform state |
| `AWS_REGION` | Variable | Regiao AWS (ex: `us-east-1`) |
| `AWS_ACCESS_KEY_ID` | Secret | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret | Credencial AWS |
| `AWS_SESSION_TOKEN` | Secret | Credencial AWS (sessao temporaria) |
| `JWT_SECRET_KEY` | Secret | Chave de assinatura JWT (`TF_VAR_jwt_secret`) |
| `DB_PASSWORD` | Secret | Senha do banco de dados (`TF_VAR_db_password`) |

---

## Estrutura do Projeto

```
oficina-tech-api-gateway/
├── lambda/
│   ├── auth/
│   │   ├── index.js         Lambda de autenticacao via CPF (POST /auth/login)
│   │   ├── utils.js         Funcoes utilitarias (validacao CPF, formatacao)
│   │   └── package.json     Dependencias: jsonwebtoken, bcryptjs, pg
│   ├── authorizer/          Diretorio reservado (sem implementacao)
│   └── auth.zip             Pacote Lambda gerado pelo pipeline
├── openapi/
│   ├── paths/               Definicao modular de rotas por dominio (fonte de verdade)
│   │   ├── auth.json
│   │   ├── customers.json
│   │   ├── vehicles.json
│   │   ├── products.json
│   │   ├── inventory.json
│   │   ├── services.json
│   │   ├── service-orders.json
│   │   └── users.json
│   └── base.json            securitySchemes, respostas de gateway, validadores
├── scripts/
│   └── build-openapi-consolidated.py  merge dos paths -> openapi-spec.json
├── terraform/
│   ├── modules/
│   │   ├── api-gateway/     API Gateway, stage, usage plan, CloudWatch
│   │   └── lambda/          Lambda function, VPC config, IAM role
│   └── environments/
│       └── production/
│           ├── main.tf          instancia os modulos
│           ├── data-sources.tf  remote state (infra + db)
│           ├── monitoring.tf    CloudWatch alarms
│           └── variables.tf
├── openapi-spec.json        spec consolidada (gerado pelo script, nao editar)
├── terraform.tfvars.example exemplo de variaveis de ambiente
└── Makefile                 comandos automatizados
```

# framecast-gateway

Ponto de entrada único da plataforma Framecast. Provisiona via Terraform o AWS API Gateway REST (regional) com WAF, VPC Link, rate limiting, monitoramento CloudWatch e integração HTTP proxy transparente com a `framecast-api` no EKS.

---

## O que este repo provisiona

| Recurso AWS                     | Descrição                                                                            |
| ------------------------------- | ------------------------------------------------------------------------------------ |
| `aws_api_gateway_rest_api`      | REST API regional `framecast-api-gw-{environment}`                                   |
| `aws_api_gateway_deployment`    | Deployment acionado por `sha1(openapi-spec.json)` — mesmo spec = sem novo deployment |
| `aws_api_gateway_stage`         | Stage `v1` com throttling, logging e cache configuráveis                             |
| `aws_api_gateway_vpc_link`      | VPC Link → NLB `framecast-infra` (NodePort 30080)                                    |
| `aws_wafv2_web_acl`             | WAF com Common + KnownBadInputs managed rules + rate-based (2k req/5min/IP)          |
| `aws_wafv2_web_acl_association` | Associação do WAF ao stage `v1`                                                      |
| `aws_cloudwatch_metric_alarm`   | Alarmes 5XX (≥10), 4XX (≥100), latência (≥5000ms)                                    |

> `enable_logging=false` por padrão — LabRole não tem permissão `apigateway:UpdateRestApiAccount`. Habilite em contas sem essa restrição.

---

## Arquitetura

```
Internet
    │
    ▼
AWS WAFv2 WebACL  (Common + KnownBadInputs + rate-based 2k req/5min/IP)
    │
    ▼
API Gateway REST  stage v1  (throttle 100 req/s · burst 500 · request validation)
    │  connectionType=VPC_LINK
    ▼
VPC Link → NLB :80 → NodePort 30080
    │
    ▼
framecast-api (EKS)
```

**Fronteiras (não gerenciado aqui):**

- NLB, EKS, VPC, S3, SQS, SES → `framecast-infra`
- RDS → `framecast-db`
- Auth JWT, upload multipart, lógica de negócio → `framecast-api`

---

## Rotas

| Método | Rota                            | Auth    | Integração             | Timeout |
| ------ | ------------------------------- | ------- | ---------------------- | ------- |
| POST   | `/api/auth/register`            | público | `http_proxy`           | 29s     |
| POST   | `/api/auth/login`               | público | `http_proxy`           | 29s     |
| POST   | `/api/auth/logout`              | Bearer  | `http_proxy`           | 29s     |
| POST   | `/api/videos/upload/init`       | Bearer  | `http_proxy`           | 29s     |
| POST   | `/api/videos/upload/parts`      | Bearer  | `http_proxy`           | 29s     |
| GET    | `/api/videos/upload/{id}/parts` | Bearer  | `http_proxy`           | 29s     |
| POST   | `/api/videos/upload/complete`   | Bearer  | `http_proxy`           | 29s     |
| DELETE | `/api/videos/upload/{id}`       | Bearer  | `http_proxy`           | 29s     |
| GET    | `/api/videos`                   | Bearer  | `http_proxy`           | 29s     |
| GET    | `/api/videos/{id}`              | Bearer  | `http_proxy`           | 29s     |
| GET    | `/health`                       | público | `mock` (200 estático)  | —       |
| GET    | `/api/health`                   | público | `http_proxy`           | 10s     |
| ANY    | `/{proxy+}`                     | —       | `http_proxy` catch-all | 29s     |

**Upload binário não passa pelo gateway** — bytes vão direto ao S3 via presigned PUT. O gateway processa apenas o JSON de controle (init/parts/complete/abort).

**O gateway não autentica.** O header `Authorization: Bearer <token>` é passado como-está para a `framecast-api`, que valida o JWT.

---

## OpenAPI modular

A spec é **gerada** — nunca editar `openapi-spec.json` diretamente.

```
openapi/
├── base.json               # schemas, securitySchemes, gateway-responses, validadores
└── paths/
    ├── auth.json           # POST /api/auth/{register,login,logout}
    ├── videos.json         # upload control-plane (init/parts/complete/abort)
    ├── status.json         # GET /api/videos, /{id}
    ├── health.json         # GET /health (mock) + /api/health (proxy)
    └── proxy.json          # ANY /{proxy+} catch-all
```

Gerar a spec antes de qualquer `terraform apply`:

```bash
python3 scripts/build-openapi-consolidated.py
```

---

## Variáveis Terraform

| Variável                 | Obrigatória | Padrão       | Descrição                                                         |
| ------------------------ | ----------- | ------------ | ----------------------------------------------------------------- |
| `tf_state_bucket`        | **✅**      | —            | Bucket S3 do remote state (ex: `fiap-soat-tf-backend-framecast`)  |
| `environment`            | —           | `production` | Nome do ambiente                                                  |
| `stage_name`             | —           | `v1`         | Stage do API Gateway                                              |
| `enable_vpc_link`        | —           | `true`       | VPC Link; `false` usa `INTERNET` (dev/LocalStack)                 |
| `enable_waf`             | —           | `true`       | WAF; `false` se LabRole não tem `wafv2:*`                         |
| `framecast_api_endpoint` | —           | `""`         | Override do endpoint (vazio = NLB DNS:30080 via remote state)     |
| `nodeport`               | —           | `30080`      | NodePort da `framecast-api` no NLB                                |
| `waf_rate_limit`         | —           | `2000`       | Req/5min/IP antes de bloquear                                     |
| `throttle_burst_limit`   | —           | `500`        | Burst do API Gateway (prod: 5000)                                 |
| `throttle_rate_limit`    | —           | `100`        | Rate limit req/s (prod: 10000)                                    |
| `enable_logging`         | —           | `false`      | CloudWatch access logs (requer `apigateway:UpdateRestApiAccount`) |
| `enable_alarms`          | —           | `true`       | Alarmes CloudWatch 5XX/4XX/latência                               |
| `error_threshold_5xx`    | —           | `10`         | Threshold do alarme 5XX                                           |
| `error_threshold_4xx`    | —           | `100`        | Threshold do alarme 4XX                                           |
| `latency_threshold_ms`   | —           | `5000`       | Threshold de latência (ms)                                        |
| `xray_tracing_enabled`   | —           | `false`      | X-Ray tracing no stage                                            |
| `enable_cache`           | —           | `false`      | Cache de respostas (custo extra)                                  |
| `lab_role`               | —           | `""`         | ARN do LabRole (vazio = derivado do account_id)                   |

Ver `terraform.tfvars.example` para valores recomendados em produção.

---

## Estrutura do projeto

```
framecast-gateway/
├── openapi/
│   ├── base.json
│   └── paths/
│       ├── auth.json · videos.json · status.json · health.json · proxy.json
├── openapi-spec.json           # GERADO — não editar diretamente
├── scripts/
│   └── build-openapi-consolidated.py
├── terraform/
│   ├── modules/
│   │   ├── api-gateway/        # REST API, stage, deployment
│   │   ├── vpc-link/           # aws_api_gateway_vpc_link → nlb_arn
│   │   └── waf/                # WAFv2 WebACL + association
│   └── environments/production/
│       ├── main.tf             # instancia módulos, monta openapi_spec via templatefile
│       ├── data-sources.tf     # remote state framecast-infra + locals
│       ├── monitoring.tf       # CloudWatch alarms
│       ├── variables.tf
│       ├── outputs.tf
│       ├── backend.tf          # key: framecast/gateway/terraform.tfstate
│       └── provider.tf
├── Makefile
└── .github/{workflows,actions}
```

---

## Como fazer deploy

### Pré-requisitos

- Terraform >= 1.7.0
- `framecast-infra` aplicado (provê `nlb_arn`, `nlb_dns_name` no remote state)
- Python 3 (para gerar `openapi-spec.json`)

```bash
# 1. Gerar a spec OpenAPI consolidada
python3 scripts/build-openapi-consolidated.py

# 2. Inicializar Terraform com remote state
cd terraform/environments/production
terraform init \
  -backend-config="bucket=fiap-soat-tf-backend-framecast" \
  -backend-config="region=us-east-1"

# 3. Planejar e aplicar
terraform plan
terraform apply
```

### Para dev/LocalStack (sem VPC Link e sem WAF)

```hcl
# terraform.tfvars
enable_vpc_link        = false
enable_waf             = false
framecast_api_endpoint = "localhost:8080"
```

---

## CI/CD

| Workflow       | Trigger                                                | O que faz                                                                                     |
| -------------- | ------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| `ci.yml`       | PR para `develop`/`main`; push em `develop`            | Build OpenAPI → `tf validate` + structure check → security scan (tfsec + checkov) → `tf plan` |
| `release.yml`  | Push em `develop` (paths: terraform/openapi/scripts)   | Calcula versão (conventional commits) → cria/atualiza branch `release/vX.Y.Z` + draft PR      |
| `deploy.yml`   | PR `release/*` mergeado em `main`; `workflow_dispatch` | Build OpenAPI → `terraform apply` → health check (5× retry, 30s) → GitHub Release             |
| `rollback.yml` | `workflow_dispatch` (versão + ambiente)                | Checkout da tag → rebuild spec → `terraform apply` sem nova tag                               |
| `destroy.yml`  | `workflow_dispatch` (confirmação manual)               | Build spec + `terraform destroy`                                                              |

### Variáveis e secrets obrigatórios no GitHub

| Nome                    | Tipo     | Descrição                                             |
| ----------------------- | -------- | ----------------------------------------------------- |
| `TF_STATE_BUCKET`       | Variable | Bucket S3 do state (`fiap-soat-tf-backend-framecast`) |
| `TF_WORKING_DIR`        | Variable | `terraform/environments/production`                   |
| `AWS_REGION`            | Variable | `us-east-1`                                           |
| `TF_VERSION`            | Variable | `1.7.0`                                               |
| `AWS_ACCESS_KEY_ID`     | Secret   | Credencial AWS                                        |
| `AWS_SECRET_ACCESS_KEY` | Secret   | Credencial AWS                                        |
| `AWS_SESSION_TOKEN`     | Secret   | Sessão temporária (Academy LabRole)                   |

---

## Outputs Terraform

| Output                | Descrição                                        |
| --------------------- | ------------------------------------------------ |
| `api_gateway_url`     | URL pública do stage (entry point da plataforma) |
| `api_gateway_id`      | REST API ID                                      |
| `vpc_link_id`         | ID do VPC Link                                   |
| `waf_web_acl_arn`     | ARN do WebACL                                    |
| `test_health_command` | `curl -s <url>/health`                           |
| `test_login_command`  | curl de smoke test de login                      |

---

## Repos do ecossistema

| Repo                | Descrição                                           |
| ------------------- | --------------------------------------------------- |
| `framecast-api`     | API + frontend SPA (EKS)                            |
| `framecast-worker`  | Consumer SQS: FFmpeg + ZIP + SES (EKS, KEDA)        |
| `framecast-infra`   | Terraform: EKS, NLB, S3, SQS, KEDA, Datadog         |
| `framecast-db`      | Terraform RDS (schema via GORM AutoMigrate)         |
| `framecast-gateway` | **Este repositório** — API Gateway + WAF + VPC Link |

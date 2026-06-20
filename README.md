# framecast-gateway

Ponto de entrada único da plataforma Framecast. Provisiona via Terraform o AWS API Gateway REST (regional) com WAF, VPC Link, rate limiting, monitoramento CloudWatch e integração HTTP proxy transparente com a `framecast-api` no EKS.

> Plano de implementação: `PLAN_FRAMECAST_GATEWAY.md`
> Workflows CI/CD: `.github/README.md`

---

## O que este repo provisiona

| Recurso AWS | Descrição |
|---|---|
| `aws_api_gateway_rest_api` | REST API regional `framecast-api-gw-{environment}` |
| `aws_api_gateway_deployment` | Deployment acionado por `sha1(openapi-spec.json)` |
| `aws_api_gateway_stage` | Stage `v1` com logging e cache configuráveis |
| `aws_api_gateway_usage_plan` | Plano com throttling (10k req/s, burst 5k) e quota diária (1M) |
| `aws_api_gateway_vpc_link` | VPC Link → NLB `framecast-infra` (NodePort 30080) |
| `aws_wafv2_web_acl` | WAF com Common + KnownBadInputs managed rules + rate-based (2k/5min/IP) |
| `aws_wafv2_web_acl_association` | Associação do WAF ao stage `v1` |
| `aws_cloudwatch_log_group` | `/aws/apigateway/framecast-{environment}` (retenção: 7 dias) |
| `aws_cloudwatch_metric_alarm` | Alarmes 5XX, 4XX, latência |

---

## Arquitetura

```
Internet
    │
    ▼
AWS WAFv2 WebACL  (Common + KnownBadInputs managed rules + rate-based 2k/5min)
    │
    ▼
API Gateway REST v1  (throttle 10k req/s · usage plan · request validation)
    │  connectionType=VPC_LINK
    ▼
VPC Link → NLB :80 → NodePort 30080
    │
    ▼
framecast-api (EKS)
  ├── POST /api/auth/{register,login,logout}
  ├── POST /api/videos/upload/{init,parts,complete}
  ├── GET  /api/videos/upload/{id}/parts
  ├── DELETE /api/videos/upload/{id}
  ├── GET  /api/videos  (listagem + cursor pagination)
  ├── GET  /api/videos/{id}  (detalhe + presigned download)
  ├── GET  /api/videos/{id}/events  (SSE best-effort)
  ├── GET  /health  (mock 200 — liveness do gateway)
  ├── GET  /api/health  (proxy → framecast-api)
  └── ANY  /{proxy+}  (frontend embed.FS + catch-all)
```

**Fronteiras (NÃO gerenciado aqui):**
- NLB, EKS, VPC, S3, SQS, SES → `framecast-infra`
- RDS → `framecast-db`
- Auth JWT, upload multipart, lógica de negócio → `framecast-api`

---

## Rotas

| Método | Rota | Auth | Módulo |
|--------|------|------|--------|
| POST | `/api/auth/register` | público | auth |
| POST | `/api/auth/login` | público | auth |
| POST | `/api/auth/logout` | Bearer | auth |
| POST | `/api/videos/upload/init` | Bearer | videos |
| POST | `/api/videos/upload/parts` | Bearer | videos |
| GET | `/api/videos/upload/{id}/parts` | Bearer | videos |
| POST | `/api/videos/upload/complete` | Bearer | videos |
| DELETE | `/api/videos/upload/{id}` | Bearer | videos |
| GET | `/api/videos` | Bearer | status |
| GET | `/api/videos/{id}` | Bearer | status |
| GET | `/api/videos/{id}/events` | Bearer¹ | status |
| GET | `/health` | público | mock |
| GET | `/api/health` | público | proxy |
| ANY | `/{proxy+}` | — | proxy |

¹ SSE aceita token via `?access_token=` (EventSource não envia `Authorization`).

**Upload binário não passa pelo gateway** — bytes vão direto ao S3 via presigned PUT gerado pela `framecast-api`. O gateway processa apenas o JSON de controle (init/parts/complete), que é pequeno e fica bem abaixo do limite de 10 MB.

---

## Variáveis Terraform

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `environment` | `production` | Nome do ambiente |
| `stage_name` | `v1` | Stage do API Gateway |
| `tf_state_bucket` | `fiap-soat-tf-backend-framecast` | Bucket S3 do state |
| `framecast_api_endpoint` | `""` | Override do endpoint (vazio = NLB DNS:30080) |
| `nodeport` | `30080` | NodePort da framecast-api no NLB |
| `enable_vpc_link` | `true` | Usa VPC Link (false = INTERNET, útil em dev) |
| `enable_waf` | `true` | Ativa WAF (false se LabRole não tem wafv2:*) |
| `waf_rate_limit` | `2000` | Req/5min/IP antes de bloquear |
| `throttle_burst_limit` | `5000` | Burst do API Gateway |
| `throttle_rate_limit` | `10000` | Rate limit req/s |
| `quota_limit` | `1000000` | Quota diária |
| `enable_logging` | `true` | CloudWatch access logs |
| `enable_alarms` | `true` | Alarmes 5XX/4XX/latência |

---

## Como fazer deploy

### Pré-requisitos

- Terraform >= 1.7.0
- `framecast-infra` aplicado (provê `nlb_arn`, `nlb_dns_name`)
- `openapi-spec.json` gerado: `python scripts/build-openapi-consolidated.py`

```bash
cd terraform/environments/production

terraform init \
  -backend-config="bucket=fiap-soat-tf-backend-framecast" \
  -backend-config="region=us-east-1"

terraform plan
terraform apply
```

### Variáveis opcionais em `terraform.tfvars`

```hcl
enable_waf     = false  # se LabRole não tem wafv2:*
enable_vpc_link = false  # para dev/LocalStack
```

---

## CI/CD

| Workflow | Trigger | O que faz |
|---|---|---|
| `ci.yml` | PR para `develop`/`main`; push em `develop` | Build OpenAPI → validate → security scan → terraform plan |
| `release.yml` | Push em `develop` (paths terraform/openapi/scripts) | Calcula versão e cria/atualiza PR de release |
| `deploy.yml` | PR `release/*` mergeado em `main`; `workflow_dispatch` | Build OpenAPI → `terraform apply` → health check → release |
| `rollback.yml` | `workflow_dispatch` | Rebuild spec da tag + `terraform apply` sem nova tag |
| `destroy.yml` | `workflow_dispatch` (confirmação manual) | Build spec + `terraform destroy` |

### Variáveis e Secrets obrigatórios no GitHub

| Nome | Tipo | Descrição |
|------|------|-----------|
| `TF_STATE_BUCKET` | Variable | Bucket S3 do state |
| `TF_WORKING_DIR` | Variable | `terraform/environments/production` |
| `AWS_REGION` | Variable | `us-east-1` |
| `AWS_ACCESS_KEY_ID` | Secret | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Secret | Credencial AWS |
| `AWS_SESSION_TOKEN` | Secret | Sessão temporária (Academy) |

---

## Estrutura do Projeto

```
framecast-gateway/
├── openapi/
│   ├── base.json               schemas, securitySchemes, gateway-responses, validadores
│   └── paths/
│       ├── auth.json           POST /api/auth/{register,login,logout}
│       ├── videos.json         upload control-plane (init/parts/complete/abort)
│       ├── status.json         GET /api/videos, /{id}, /{id}/events
│       ├── health.json         GET /health (mock) + /api/health (proxy)
│       └── proxy.json          ANY /{proxy+} catch-all
├── scripts/
│   └── build-openapi-consolidated.py
├── terraform/
│   ├── modules/
│   │   ├── api-gateway/        REST API, stage, usage plan, CloudWatch
│   │   ├── vpc-link/           aws_api_gateway_vpc_link → nlb_arn
│   │   └── waf/                WAFv2 WebACL + association ao stage
│   └── environments/production/
│       ├── main.tf             instancia api-gateway + vpc-link + waf
│       ├── data-sources.tf     remote state framecast-infra + locals
│       ├── monitoring.tf       CloudWatch alarms
│       ├── variables.tf
│       ├── outputs.tf
│       ├── backend.tf          key: framecast/gateway/terraform.tfstate
│       └── provider.tf
├── openapi-spec.json           GERADO pelo script (não editar)
└── .github/{workflows,actions}
```

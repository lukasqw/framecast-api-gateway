# Contexto de IA — framecast-gateway

## O que é este repo

Infraestrutura Terraform do API Gateway da plataforma Framecast. Provisiona o ponto de entrada único: AWS API Gateway REST (regional) → WAF → VPC Link → NLB:30080 → `framecast-api` no EKS.

**O gateway não tem lógica de negócio e não autentica.** Auth JWT (HS256 + bcrypt) é responsabilidade exclusiva da `framecast-api`.

> Plano de implementação: `PLAN_FRAMECAST_GATEWAY.md`
> Workflows CI/CD, variáveis e secrets: `.github/README.md`

## Domínio deste repo

- Proxy seguro: WAFv2 WebACL (managed rules + rate-based) + Usage Plan throttle
- VPC Link → NLB → `framecast-api` (único backend, NodePort 30080)
- OpenAPI spec modular como fonte de verdade das rotas
- Monitoramento CloudWatch (5XX, 4XX, latência)

## Tecnologias

- **Terraform** — provisionamento AWS (módulos: `api-gateway`, `vpc-link`, `waf`)
- **OpenAPI 3.0** — spec modular `openapi/paths/` consolidada por `scripts/build-openapi-consolidated.py`
- **AWS API Gateway REST API** — regional, stage `v1`
- **AWS WAFv2** — `AWSManagedRulesCommonRuleSet` + `AWSManagedRulesKnownBadInputsRuleSet` + rate-based
- **VPC Link** — `aws_api_gateway_vpc_link` → `nlb_arn` (output do `framecast-infra`)

## Convenções

### Terraform

- `terraform/environments/production/` é a única raiz Terraform (`TF_WORKING_DIR`)
- Remote state: apenas `framecast/infra/terraform.tfstate` (sem dependência do db)
- Sem secrets de app — gateway não acessa DB nem assina JWT
- `enable_vpc_link=false` usa `connectionType=INTERNET` (útil em dev/LocalStack)
- `enable_waf=false` desabilita WAF (Academy LabRole pode não ter `wafv2:*`)

### OpenAPI

- Arquivos fonte em `openapi/paths/` (`auth`, `videos`, `status`, `health`, `proxy`)
- `openapi/base.json` define: `securitySchemes`, gateway-responses, validadores (`all`/`params-only`/`body-only`)
- Variáveis de templatefile: `framecast_api_endpoint`, `vpc_link_id`, `connection_type`, `aws_region`
- **Nunca editar `openapi-spec.json` diretamente** — gerado pelo script de build no CI
- Bytes de vídeo **não passam pelo gateway** (upload vai direto ao S3 via presigned URL)

### SSE / Streaming

`GET /api/videos/{id}/events` é proxied, mas REST API GW faz buffering e tem timeout de 29s — sem streaming real. O frontend usa polling (`GET /api/videos` a cada 10s) como fonte primária.

## Como a IA deve trabalhar neste repo

- **Nova rota:** criar/editar arquivo em `openapi/paths/`, executar `scripts/build-openapi-consolidated.py` e aplicar Terraform
- **VPC Link:** modificar `terraform/modules/vpc-link/` ou a variável `enable_vpc_link`
- **WAF rules:** modificar `terraform/modules/waf/` ou a variável `waf_rate_limit`
- **Rate limiting/cache:** ajustar variáveis em `terraform/environments/production/variables.tf`
- **Alarmes:** `enable_alarms=true` em `variables.tf`
- **Nunca** adicionar secrets de app no Terraform
- **Nunca** criar lógica de negócio ou autenticação no gateway

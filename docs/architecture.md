# Arquitetura — framecast-gateway

## Visão Geral

AWS API Gateway REST (regional) como ponto de entrada único da plataforma Framecast. Toda requisição passa por WAF → API GW → VPC Link → NLB → `framecast-api` no EKS.

O gateway é **proxy + segurança de borda** — não tem lógica de negócio e não valida JWT.

---

## Diagrama de Componentes

```
Internet
    │
    ▼
┌──────────────────────────────────────────────────┐
│  AWS WAFv2 WebACL (REGIONAL)                     │
│  · AWSManagedRulesCommonRuleSet                  │
│  · AWSManagedRulesKnownBadInputsRuleSet          │
│  · rate-based: 2000 req/5min/IP → BLOCK          │
└────────────────────┬─────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────┐
│  API Gateway REST  stage: v1                     │
│  throttle: 10k req/s  burst: 5k  quota: 1M/dia  │
│  request validator: all (body + params)          │
│  gateway-responses: CORS / 401 / 403 / 429 / 413│
└────────────────────┬─────────────────────────────┘
                     │ connectionType = VPC_LINK
                     ▼
┌──────────────────────────────────────────────────┐
│  VPC Link → NLB TCP:80 → NodePort 30080          │
└────────────────────┬─────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────┐
│  framecast-api (EKS)                             │
│  · Auth JWT HS256 + bcrypt                       │
│  · Videos multipart S3                           │
│  · Status / SSE                                  │
│  · Frontend embed.FS                             │
└──────────────────────────────────────────────────┘
```

---

## Fluxo: Rota pública (`POST /api/auth/login`)

```
Cliente  { email, password }
    │
    ▼
WAF  →  API GW (sem verificação de auth)
    │
    ▼
VPC Link → NLB → framecast-api
    │── valida email + bcrypt
    └── emite JWT HS256 (exp: 24h)
    │
    ▼
{ data: { token, user } }
```

---

## Fluxo: Rota protegida (`Bearer`)

```
Cliente  (Authorization: Bearer <jwt>)
    │
    ▼
WAF  →  API GW
    ├── Header Authorization ausente? → 401 (nativo, sem chamar backend)
    └── Header presente → passa adiante sem validar assinatura
             │  connectionType=VPC_LINK  timeout=29s
             ▼
    NLB → framecast-api
             ├── valida assinatura JWT (HS256)
             ├── verifica expiração + token_invalidated_at
             └── aplica ownership (404 para recurso de outro usuário)
```

---

## Fluxo: Upload de vídeo

```
1. Cliente → POST /api/videos/upload/init   (JSON pequeno)
   Gateway → VPC Link → framecast-api → cria registro + inicia multipart S3
   Resposta: { video_id, upload_id }

2. Cliente → POST /api/videos/upload/parts  (JSON pequeno)
   Gateway → VPC Link → framecast-api → gera presigned PUT URLs
   Resposta: [{ part_number, url }]

3. Cliente → PUT <presigned URL> <bytes do vídeo>   ← DIRETO AO S3, NÃO PASSA PELO GATEWAY
   S3 responde: ETag por parte

4. Cliente → POST /api/videos/upload/complete  (JSON com ETags)
   Gateway → VPC Link → framecast-api → CompleteMultipartUpload + publica SQS

5. framecast-worker (SQS) → FFmpeg → ZIP → S3 → DB status=DONE → SES
```

**Por que o binário não passa pelo gateway:** limite de 10 MB de payload do API Gateway. O upload vai direto ao S3 via presigned URLs — o gateway nunca toca nos bytes do vídeo.

---

## Integração com o Backend

| Parâmetro | Valor |
|-----------|-------|
| Tipo | `http_proxy` |
| connectionType | `VPC_LINK` (fallback `INTERNET` se `enable_vpc_link=false`) |
| Endpoint | `http://{nlb_dns}:30080` (derivado do remote state `framecast-infra`) |
| Timeout | 29 segundos (máximo do REST API GW) |
| Header passthrough | Todos os headers originais, incluindo `Authorization` |

---

## WAF

| Regra | Tipo | Ação |
|-------|------|------|
| `AWSManagedRulesCommonRuleSet` | Managed | Block (override none) |
| `AWSManagedRulesKnownBadInputsRuleSet` | Managed | Block (override none) |
| `RateBasedByIP` | Rate-based | Block (>2000 req/5min por IP) |

Toggle `enable_waf=false` desabilita o WAF sem quebrar o apply (necessário se LabRole não tiver `wafv2:*`).

---

## Remote State Consumido

| Output | Fonte | Uso |
|--------|-------|-----|
| `nlb_arn` | `framecast/infra/terraform.tfstate` | Target do VPC Link |
| `nlb_dns_name` | `framecast/infra/terraform.tfstate` | Endpoint de integração |

---

## Monitoramento

| Alarme | Métrica | Threshold | Janela |
|--------|---------|-----------|--------|
| `framecast-api-5xx-{env}` | `5XXError` (Sum) | 10 | 2× 5min |
| `framecast-api-4xx-{env}` | `4XXError` (Sum) | 100 | 2× 5min |
| `framecast-api-latency-{env}` | `Latency` (Avg) | 5000ms | 2× 5min |

- Log group: `/aws/apigateway/framecast-{environment}`
- Dimensões: `ApiName` + `Stage` do módulo `api-gateway`

---

## Limitações Conhecidas

**SSE (`GET /api/videos/{id}/events`):** REST API GW faz buffering e tem timeout de 29s — sem streaming em tempo real. O frontend usa polling (`GET /api/videos` a cada 10s) como fonte primária de status; SSE é complemento. Alternativa (SSE direto no NLB) está fora de escopo.

**Tamanho de payload:** máximo 10 MB pelo API GW — endereçado por fazer o upload ir direto ao S3.

**VPC Link:** criação/atualização pode levar vários minutos. Pipeline com `timeout-minutes: 45`.

**State sem lock:** `concurrency: deploy` no workflow previne applies paralelos.

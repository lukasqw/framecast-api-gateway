# Regras de Negócio — framecast-gateway

Este repo é majoritariamente infraestrutura, mas tem regras de comportamento bem definidas.

---

## Autenticação no Gateway

- O gateway **não valida JWT** — apenas verifica a *presença* do header `Authorization: Bearer` via `BearerAuth` (tipo `apiKey` nativo do OpenAPI)
- Header ausente → `401` devolvido pelo próprio API Gateway, sem chamar o backend
- Header presente → passado adiante intacto para a `framecast-api` validar
- **Não há Lambda Authorizer** — assinatura, expiração e ownership são responsabilidade exclusiva da `framecast-api`

---

## Rotas Públicas vs. Protegidas

| Rota | Auth gateway | Auth backend |
|------|-------------|-------------|
| `POST /api/auth/register` | nenhuma | nenhuma |
| `POST /api/auth/login` | nenhuma | valida email+bcrypt |
| `GET /health` | nenhuma | mock (sem backend) |
| `GET /api/health` | nenhuma | nenhuma |
| Todas as demais | `BearerAuth` (presença do header) | JWT HS256 + ownership |

---

## Upload Binário Não Passa pelo Gateway

- `POST /api/videos/upload/init` → retorna `upload_id`
- `POST /api/videos/upload/parts` → retorna presigned PUT URLs do S3
- Cliente faz `PUT <presigned URL> <bytes>` **direto ao S3** — sem passar pelo gateway
- `POST /api/videos/upload/complete` → completa o multipart + enfileira SQS

Razão: limite de 10 MB de payload do API Gateway. Bytes de vídeo jamais devem passar por aqui.

---

## SSE — Limitação de Streaming

`GET /api/videos/{id}/events` é proxied, mas REST API Gateway:
- Faz buffering da resposta (sem streaming real)
- Timeout de integração: 29 segundos

O frontend usa `GET /api/videos` (polling a cada 10s) como fonte primária de status. SSE via `?access_token=<jwt>` (EventSource não envia header `Authorization`) é complemento, não garantia.

---

## Rate Limiting

Duas camadas independentes:

| Camada | Configuração | Resposta |
|--------|-------------|----------|
| WAF (por IP) | 2000 req/5min por IP | HTTP 403 (WAF block) |
| Usage Plan (por stage) | 10k req/s, burst 5k, quota 1M/dia | HTTP 429 com `Retry-After: 60` |

---

## CORS

Headers em todas as respostas de erro do gateway (DEFAULT_4XX, DEFAULT_5XX, 401, 403, 429, 413):

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token
```

Frontend é same-origin (servido pela `framecast-api` via `embed.FS`). CORS cobre chamadas cross-origin eventuais.

---

## Validação de Requisições

- Validador padrão: `all` (body + parâmetros)
- Rotas de auth com body: `body-only`
- Rotas só com path params: `params-only`
- Requisição malformada rejeitada pelo gateway antes de chegar ao backend

---

## Envelope de Resposta de Erro

Todas as respostas de erro do gateway seguem o envelope da `framecast-api`:

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "missing or invalid Authorization header"
  }
}
```

---

## Configuração VPC Link

- `enable_vpc_link=true` (padrão): `connectionType=VPC_LINK`, `connectionId=<vpc_link_id>`
- `enable_vpc_link=false` (dev/LocalStack): `connectionType=INTERNET`, `connectionId=""`
- Trocar esse toggle força redeploy do stage (spec muda → `sha1` muda → novo deployment)

---

## Prefixo de Rota

Todas as rotas são prefixadas pelo stage `v1`:

```
POST /api/auth/login → https://<api-id>.execute-api.us-east-1.amazonaws.com/v1/api/auth/login
GET  /health         → https://<api-id>.execute-api.us-east-1.amazonaws.com/v1/health
```

---

## Idempotência

O gateway não tem estado próprio. Idempotência é garantida pela `framecast-api`:
- `POST /api/videos/upload/complete`: se vídeo já está `PROCESSING`/`DONE`, não republica SQS
- `POST /api/auth/logout`: invalida via `token_invalidated_at` no banco

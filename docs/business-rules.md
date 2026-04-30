# Regras de Negócio — oficina-tech-api-gateway

Este repo é majoritariamente infraestrutura, mas tem regras de comportamento bem definidas que devem ser mantidas.

---

## Autenticação

- **Todas as rotas** exceto `POST /auth/login` exigem o header `Authorization: Bearer <token>`
- A verificação de presença do header é feita via `BearerAuth` (tipo `apiKey` nativo do API Gateway, declarado no OpenAPI)
- **Não há Lambda Authorizer implementado** — a validação de assinatura e expiração do JWT é responsabilidade do backend (`oficina-tech`)
- RBAC (permissões por role) é verificado exclusivamente no backend
- A rota `POST /auth/login` é processada pela Lambda de autenticação (não é proxy para o backend)
- A rota `POST /auth/validate` é proxy para o backend e **exige** `BearerAuth`

## Lambda de Autenticação (`POST /auth/login`)

- Recebe: `cpf` (string), `password` (string), `type` (`"user"` ou `"customer"`)
- O campo `type` é obrigatório — determina qual tabela consultar (`users` ou `customers`)
- CPF é validado com algoritmo completo de dígitos verificadores (módulo 11)
- CPF com todos os dígitos iguais é rejeitado
- Senha mínima de 6 caracteres; comparada via `bcryptjs` contra o hash no banco
- Contas com `deleted_at` preenchido retornam `403 INACTIVE_ACCOUNT`
- Emite JWT HS256 com `JWT_SECRET` (variável de ambiente)
- Validade do token: **24 horas** (`exp = iat + 86400`)

### Claims do JWT emitido

| Campo | Valor |
|-------|-------|
| `user_id` | UUID da entidade |
| `sub` | UUID da entidade |
| `email` | Email |
| `name` | Nome |
| `cpf` | CPF (campo `cpf` ou `document`) |
| `role` | Role do usuário (`ADMIN`, `MANAGER`, `USER`) ou `CUSTOMER` para clientes |
| `type` | `"user"` ou `"customer"` |
| `iss` | `"oficina-tech"` |
| `aud` | `"oficina-tech-api"` |

### Códigos de erro da Lambda

| Código HTTP | Código de erro | Motivo |
|-------------|---------------|--------|
| 400 | `INVALID_CPF` | CPF inválido |
| 400 | `MISSING_FIELDS` | Campos obrigatórios ausentes |
| 400 | `INVALID_TYPE` | `type` não é `"user"` nem `"customer"` |
| 401 | `INVALID_CREDENTIALS` | CPF não encontrado ou senha incorreta |
| 403 | `INACTIVE_ACCOUNT` | Conta com soft delete ativo |
| 500 | `INTERNAL_ERROR` | Erro no banco ou inesperado |

## Headers Injetados no Backend

Após validação do token, o gateway injeta os seguintes headers em todas as requisições autenticadas:

| Header | Origem |
|--------|--------|
| `X-User-Id` | `context.authorizer.userId` |
| `X-User-Role` | `context.authorizer.role` |
| `X-User-Email` | `context.authorizer.email` |
| `Authorization` | Header original do cliente (passado adiante) |

## Rate Limiting

- **Rate limit:** 10.000 requisições/segundo por stage
- **Burst:** 5.000 requisições simultâneas
- **Quota:** 1.000.000 requisições/dia
- Ao exceder: resposta `429 Too Many Requests` com body `{"errors":[{"code":"RATE_LIMIT_EXCEEDED","message":"Too many requests"}]}`
- Header `Retry-After: 60` incluso na resposta 429

## Cache

- TTL padrão: **300 segundos** (5 minutos)
- Tamanho padrão do cluster: **0.5 GB**
- Cache **desabilitado por padrão** — deve ser ativado explicitamente via `enable_cache = true` no Terraform
- Quando ativo: dados em cache são criptografados em repouso

## CORS

- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Headers: Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`
- Respostas de erro padrão do gateway (4XX, 5XX, 401, 403, 429) também incluem headers CORS

## Validação de Requisições

- Validador padrão: `all` — valida tanto body quanto parâmetros de query/path
- Requisição malformada rejeitada pelo gateway antes de chegar ao backend

## Prefixo de Rota

Todas as rotas são prefixadas pelo nome do stage. Stage padrão: **`v1`**.

- Exemplo: `POST /auth/login` → `https://<api-id>.execute-api.us-east-1.amazonaws.com/v1/auth/login`

## Integração com o Backend

- Todas as rotas (exceto `POST /auth/login`) são **HTTP proxy transparente** para o NLB/ALB do EKS
- Timeout da integração: **29 segundos**
- `passthroughBehavior: when_no_match`

## Rotas Disponíveis

| Método | Rota | Autenticação |
|--------|------|-------------|
| POST | `/auth/login` | Pública |
| POST | `/auth/validate` | BearerAuth |
| GET | `/customers` | BearerAuth |
| POST | `/customers` | BearerAuth |
| GET | `/customers/{id}` | BearerAuth |
| PUT | `/customers/{id}` | BearerAuth |
| DELETE | `/customers/{id}` | BearerAuth |
| GET | `/vehicles` | BearerAuth |
| POST | `/vehicles` | BearerAuth |
| GET | `/vehicles/{id}` | BearerAuth |
| PUT | `/vehicles/{id}` | BearerAuth |
| DELETE | `/vehicles/{id}` | BearerAuth |
| POST | `/products` | BearerAuth |
| GET | `/products/{id}` | BearerAuth |
| PUT | `/products/{id}` | BearerAuth |
| DELETE | `/products/{id}` | BearerAuth |
| GET | `/products/{id}/inventory` | BearerAuth |
| POST | `/products/{id}/inventory` | BearerAuth |
| POST | `/products/{id}/inventory/reserve` | BearerAuth |
| POST | `/products/{id}/inventory/cancel-reserved` | BearerAuth |
| POST | `/products/{id}/inventory/increase` | BearerAuth |
| POST | `/products/{id}/inventory/manual-decrease` | BearerAuth |
| POST | `/products/{id}/inventory/reserved-decrease` | BearerAuth |
| GET | `/services` | BearerAuth |
| POST | `/services` | BearerAuth |
| GET | `/services/{id}` | BearerAuth |
| PUT | `/services/{id}` | BearerAuth |
| DELETE | `/services/{id}` | BearerAuth |
| GET | `/service-orders` | BearerAuth |
| POST | `/service-orders` | BearerAuth |
| GET | `/service-orders/{id}` | BearerAuth |
| PUT | `/service-orders/{id}` | BearerAuth |
| DELETE | `/service-orders/{id}` | BearerAuth |
| POST | `/service-orders/{id}/advance-status` | BearerAuth |
| GET | `/service-orders/{id}/history` | BearerAuth |
| POST | `/users` | BearerAuth |
| GET | `/users/{id}` | BearerAuth |
| PUT | `/users/{id}` | BearerAuth |
| DELETE | `/users/{id}` | BearerAuth |

> Para adicionar uma nova rota: editar o arquivo correspondente em `openapi/paths/`, rodar `scripts/build-openapi-consolidated.py` e aplicar Terraform.

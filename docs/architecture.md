# Arquitetura — oficina-tech-api-gateway

## Visão Geral

AWS API Gateway REST API (regional) que serve como ponto de entrada único da plataforma. Toda requisição passa por aqui antes de chegar ao backend Go no EKS.

---

## Diagrama de Componentes

```
Cliente HTTP
     │
     ▼
┌────────────────────────────────────────────────────────────┐
│               AWS API Gateway REST (Regional)              │
│                         Stage: v1                          │
│                                                            │
│  Rate limit: 10.000 req/s  │  Burst: 5.000  │  Quota: 1M/dia  │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Validação OpenAPI (request validator: "all")       │   │
│  │  Verifica presença do header Authorization          │   │
│  └─────────────┬───────────────────────┬───────────────┘   │
│                │                       │                   │
│    POST /auth/login              Demais rotas              │
│                │                 (BearerAuth)              │
│                ▼                       │                   │
│  ┌─────────────────────┐              ▼                   │
│  │  Lambda Auth CPF    │   HTTP Proxy → NLB → EKS Pod     │
│  │  Node.js 20.x       │   (oficina-tech)                 │
│  │  Consulta RDS       │                                  │
│  │  diretamente        │                                  │
│  └─────────────────────┘                                  │
└────────────────────────────────────────────────────────────┘
```

---

## Fluxo: POST /auth/login (rota pública)

```
Cliente
  │  { cpf, password, type }
  ▼
API Gateway (sem verificação de auth)
  │
  ▼
Lambda Auth CPF (Node.js 20.x)
  ├── Valida campos obrigatórios (cpf, password, type)
  ├── Valida formato e dígitos verificadores do CPF
  ├── Consulta RDS PostgreSQL
  │     ├── type="user"     → tabela users (campo cpf)
  │     └── type="customer" → tabela customers (campo document, document_type='CPF')
  ├── Verifica deleted_at → 403 INACTIVE_ACCOUNT
  ├── Compara senha com bcryptjs
  └── Emite JWT HS256 (exp: 24h, iss: "oficina-tech", aud: "oficina-tech-api")
  │
  ▼
Cliente recebe { data: { token, user } }
```

---

## Fluxo: Rotas protegidas (BearerAuth)

```
Cliente (com JWT no header Authorization)
  │
  ▼
API Gateway
  ├── Header Authorization ausente? → 401 (gateway nativo)
  └── Header presente → passa adiante
         │
         ▼
  HTTP Proxy Integration (timeout: 29s)
         │
         ▼
  NLB → EKS Pod (oficina-tech)
         ├── Backend valida assinatura JWT (HS256)
         ├── Backend verifica expiração
         └── Backend aplica RBAC por rota
```

> **Nota:** Não há Lambda Authorizer implementado. A validação do JWT (assinatura + expiração) e o RBAC são responsabilidade exclusiva do backend `oficina-tech`.

---

## Headers Injetados no Backend

O gateway injeta os seguintes headers em requisições autenticadas, extraídos de `context.authorizer`:

| Header | Conteúdo |
|--------|----------|
| `X-User-Id` | UUID do usuário/cliente |
| `X-User-Role` | Role (`ADMIN`, `MANAGER`, `USER`, `CUSTOMER`) |
| `X-User-Email` | Email |
| `Authorization` | Token original (passado adiante) |

---

## Estrutura do Projeto

```
oficina-tech-api-gateway/
├── lambda/
│   ├── auth/
│   │   └── index.js        ← Lambda de autenticação via CPF (POST /auth/login)
│   └── authorizer/         ← diretório reservado (sem implementação)
├── openapi/
│   ├── paths/              ← definição modular de rotas por domínio (fonte de verdade)
│   │   ├── auth.json
│   │   ├── customers.json
│   │   ├── vehicles.json
│   │   ├── products.json
│   │   ├── inventory.json
│   │   ├── services.json
│   │   ├── service-orders.json
│   │   └── users.json
│   └── base.json           ← schemas, securitySchemes, respostas gateway, validadores
├── scripts/
│   └── build-openapi-consolidated.py  ← merge dos paths → openapi-spec.json
├── terraform/
│   ├── modules/
│   │   ├── api-gateway/    ← módulo: API Gateway, stage, usage plan, CloudWatch
│   │   └── lambda/         ← módulo: Lambda function, VPC config, IAM role
│   └── environments/
│       └── production/
│           ├── main.tf         ← instancia os módulos
│           ├── data-sources.tf ← remote state (infra + db)
│           ├── monitoring.tf   ← CloudWatch alarms
│           └── variables.tf
└── openapi-spec.json       ← spec consolidada (gerado pelo script, não editar)
```

---

## Integração com o Backend (HTTP Proxy)

- **Destino:** NLB resolvido via remote state Terraform (`data.terraform_remote_state.main.outputs.nlb_dns_name`)
- **Tipo:** `http_proxy` — headers e body passados sem modificação
- **Timeout:** 29 segundos
- **Fallback de endpoint:** `http://placeholder.elb.us-east-1.amazonaws.com` (quando remote state indisponível)

---

## Cache

| Configuração | Valor |
|---|---|
| Estado padrão | **Desabilitado** (`enable_cache = false`) |
| TTL quando ativo | 300 segundos |
| Tamanho do cluster | 0.5 GB (padrão) |
| Criptografia | Sim (quando ativo) |

---

## Monitoramento

Alertas CloudWatch em `monitoring.tf` — **desabilitados por padrão** (`enable_alarms = false`):

| Alarme | Métrica | Threshold | Janela |
|--------|---------|-----------|--------|
| 5XX errors | `5XXError` (Sum) | 10 erros | 2× 5 min |
| 4XX errors | `4XXError` (Sum) | 100 erros | 2× 5 min |
| Latência | `Latency` (Average) | 5.000 ms | 2× 5 min |

- **Log group:** `/aws/apigateway/oficina-tech-{environment}`
- **Retenção dos logs:** 7 dias (padrão)
- **Logging e X-Ray:** desabilitados por padrão

---

## Decisões Técnicas

**Por que REST API (não HTTP API)?**
Maior controle sobre throttling por recurso/método, cache e respostas de gateway customizadas.

**Por que OpenAPI modular?**
A spec consolidada tem ~88KB. Manter arquivos separados por domínio facilita revisão de PRs e evita conflitos de merge.

**Por que Lambda de auth em Node.js?**
Cold start mais rápido para funções stateless; `bcryptjs` e `pg` têm suporte maduro no ecossistema Node.

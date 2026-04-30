# Contexto de IA — oficina-tech-api-gateway

> Leia também o [contexto global](../claude.md) antes de trabalhar neste repo.

## O que é este repo

Infraestrutura do AWS API Gateway da plataforma Oficina Tech. Provisiona como código (Terraform) o ponto de entrada único da plataforma: AWS API Gateway REST API (regional) com rate limiting, cache, monitoramento e integração HTTP proxy com o backend Go no EKS.

> Fluxo completo de autenticação e roteamento: [docs/architecture.md](docs/architecture.md)
> Regras de comportamento do gateway: [docs/business-rules.md](docs/business-rules.md)
> Workflows CI/CD, actions, variáveis e secrets: [.github/README.md](.github/README.md)

## Domínio deste repo

Este repo **não tem lógica de negócio**. Seu domínio é infraestrutura de entrada:

- Configuração do API Gateway (rotas, métodos, integrações HTTP proxy)
- Lambda de autenticação via CPF (`POST /auth/login`) — única rota não-proxy
- OpenAPI spec como fonte de verdade das rotas
- Monitoramento e alertas de CloudWatch

> **Não há Lambda Authorizer implementado.** A validação de JWT e RBAC são responsabilidade do backend `oficina-tech`. Ver [docs/business-rules.md](docs/business-rules.md#autenticação).

## Tecnologias

- **Terraform** — provisionamento de toda a infraestrutura AWS
- **Node.js 20.x** — Lambda de autenticação (`lambda/auth/index.js`)
- **OpenAPI 3.0** — spec modular que define as rotas do API Gateway
- **AWS API Gateway REST API** — regional, stage `v1`
- **PostgreSQL** — consultado diretamente pela Lambda de auth via `pg` + pool de conexão

## Convenções específicas

### Terraform

- Módulos reutilizáveis em `terraform/modules/` (`api-gateway`, `lambda`)
- Configuração do ambiente em `terraform/environments/production/`
- Variáveis sensíveis via `terraform.tfvars` (nunca commitar — usar `.example`)
- Remote state: infra e RDS são lidos via `data.terraform_remote_state` em `data-sources.tf`
- Secrets sensíveis (`JWT_SECRET`, `DB_PASSWORD`) via variáveis de ambiente da Lambda — nunca hardcoded

### OpenAPI

- Spec modular: cada domínio tem seu arquivo em `openapi/paths/` (`auth`, `customers`, `vehicles`, `products`, `inventory`, `services`, `service-orders`, `users`)
- Script `scripts/build-openapi-consolidated.py` consolida tudo em `openapi-spec.json`
- Sempre editar os arquivos em `openapi/paths/`, **nunca** editar `openapi-spec.json` diretamente
- `openapi/base.json` define: `securitySchemes`, respostas de gateway (4XX/5XX/401/403/429/CORS) e os três validadores (`all`, `params-only`, `body-only`)
- Validador padrão é `all` (body + parâmetros)

### Lambda de autenticação (`lambda/auth/`)

- Única rota com lógica própria: `POST /auth/login`
- Recebe `{ cpf, password, type }` — `type` deve ser `"user"` ou `"customer"`
- Valida CPF com dígitos verificadores (módulo 11)
- Consulta o RDS diretamente (não chama o backend)
- Emite JWT HS256 com validade de 24h, `iss: "oficina-tech"`, `aud: "oficina-tech-api"`
- Ver todos os campos do token e códigos de erro em [docs/business-rules.md](docs/business-rules.md#lambda-de-autenticação-post-authlogin)

## Como a IA deve trabalhar neste repo

- **Ao adicionar nova rota:** criar/editar o arquivo correto em `openapi/paths/`, rodar `scripts/build-openapi-consolidated.py` e aplicar Terraform
- **Ao modificar a Lambda de auth:** editar `lambda/auth/index.js`; não criar lógica em `lambda/authorizer/` (diretório reservado, sem implementação)
- **Ao modificar infraestrutura:** seguir os módulos Terraform em `terraform/modules/` — não criar recursos fora deles
- **Ao alterar rate limiting ou cache:** ajustar variáveis em `terraform/environments/production/variables.tf`; cache é desabilitado por padrão (`enable_cache = false`)
- **Ao configurar alarmes:** habilitar via `enable_alarms = true`; valores padrão em [docs/architecture.md](docs/architecture.md#monitoramento)
- Nunca colocar secrets nos arquivos Terraform — usar `variables.tf` + AWS Secrets Manager

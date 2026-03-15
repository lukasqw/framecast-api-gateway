# Estrutura do API Gateway - Oficina Tech

## 📁 Estrutura de Diretórios

```
api-gateway/
│
├── 📄 README.md                    # Documentação principal
├── 📄 Makefile                     # Comandos de automação
├── 📄 .gitignore                   # Arquivos ignorados
│
├── 🔧 Terraform (Infraestrutura)
│   ├── main.tf                     # Configuração principal
│   ├── authorizer.tf               # Lambda authorizer JWT
│   ├── variables.tf                # Variáveis de entrada
│   ├── outputs.tf                  # Outputs do Terraform
│   └── terraform.tfvars.example    # Exemplo de configuração
│
├── ⭐ OpenAPI (Especificação da API)
│   ├── openapi-spec.json           # Spec consolidada (gerada)
│   └── openapi/                    # Definições modulares
│       ├── README.md               # Guia da estrutura modular
│       ├── .gitignore
│       ├── base.json               # Configuração base (60 linhas)
│       └── paths/                  # Endpoints por módulo
│           ├── auth.json           # 1 endpoint
│           ├── users.json          # 4 endpoints
│           ├── customers.json      # 5 endpoints
│           ├── vehicles.json       # 5 endpoints
│           ├── services.json       # 5 endpoints
│           ├── products.json       # 4 endpoints
│           ├── inventory.json      # 7 endpoints
│           └── service-orders.json # 7 endpoints
│
├── 🔐 Lambda (Authorizer)
│   ├── index.js                    # Validação JWT
│   ├── package.json                # Dependências Node.js
│   ├── README.md                   # Documentação
│   └── .gitignore
│
├── 🛠️ Scripts (Automação)
│   ├── build-openapi.py            # Consolida OpenAPI modular
│   └── test-endpoints.sh           # Testes de endpoints
│
└── 📚 Documentação
    └── docs/
        ├── QUICK_START.md          # Setup rápido (5 min)
        ├── ARCHITECTURE.md         # Arquitetura detalhada
        ├── DEPLOYMENT.md           # Guia de deployment
        ├── INTEGRATION.md          # Integração com infra
        ├── ENDPOINTS.md            # Referência de endpoints
        ├── PROJECT_STRUCTURE.md    # Estrutura detalhada
        └── CHANGELOG.md            # Histórico de mudanças
```

## 📊 Estatísticas

```
Total de arquivos:        ~30
Arquivos Terraform:       5
Arquivos OpenAPI:         9 (modular)
Endpoints totais:         38
Documentação:             8 arquivos
Scripts:                  2
```

## 🎯 Arquivos Principais

### 1. Terraform

| Arquivo         | Descrição                                     | Linhas |
| --------------- | --------------------------------------------- | ------ |
| `main.tf`       | API Gateway REST API, deployment, stage, logs | ~150   |
| `authorizer.tf` | Lambda function, IAM roles, authorizer config | ~100   |
| `variables.tf`  | Variáveis de configuração                     | ~50    |
| `outputs.tf`    | Outputs (URL, ARNs, etc)                      | ~30    |

### 2. OpenAPI

| Arquivo                             | Descrição                         | Endpoints |
| ----------------------------------- | --------------------------------- | --------- |
| `openapi/base.json`                 | Config base, security, validators | -         |
| `openapi/paths/auth.json`           | Autenticação                      | 1         |
| `openapi/paths/users.json`          | Gestão de usuários                | 4         |
| `openapi/paths/customers.json`      | Gestão de clientes                | 5         |
| `openapi/paths/vehicles.json`       | Gestão de veículos                | 5         |
| `openapi/paths/services.json`       | Catálogo de serviços              | 5         |
| `openapi/paths/products.json`       | Gestão de produtos                | 4         |
| `openapi/paths/inventory.json`      | Gestão de estoque                 | 7         |
| `openapi/paths/service-orders.json` | Ordens de serviço                 | 7         |
| **Total**                           |                                   | **38**    |

### 3. Lambda Authorizer

| Arquivo               | Descrição                            |
| --------------------- | ------------------------------------ |
| `lambda/index.js`     | Validação JWT, geração de IAM policy |
| `lambda/package.json` | Dependências (jsonwebtoken)          |

### 4. Scripts

| Script                      | Função                                            |
| --------------------------- | ------------------------------------------------- |
| `scripts/build-openapi.py`  | Consolida arquivos modulares em openapi-spec.json |
| `scripts/test-endpoints.sh` | Testa endpoints públicos e protegidos             |

### 5. Documentação

| Documento                   | Conteúdo                                       |
| --------------------------- | ---------------------------------------------- |
| `README.md`                 | Visão geral, quick start, comandos básicos     |
| `docs/QUICK_START.md`       | Setup em 5 minutos                             |
| `docs/ARCHITECTURE.md`      | Arquitetura, fluxo de requisições, componentes |
| `docs/DEPLOYMENT.md`        | Guia completo de deployment                    |
| `docs/INTEGRATION.md`       | Integração com ALB/EKS existente               |
| `docs/ENDPOINTS.md`         | Referência completa de todos os endpoints      |
| `docs/PROJECT_STRUCTURE.md` | Estrutura detalhada do projeto                 |
| `docs/CHANGELOG.md`         | Histórico de mudanças e versões                |
| `openapi/README.md`         | Guia da estrutura modular do OpenAPI           |

## 🔄 Workflow de Desenvolvimento

### Adicionar Novo Endpoint

```bash
# 1. Editar arquivo do módulo
vim openapi/paths/customers.json

# 2. Build OpenAPI
make build-openapi

# 3. Validar
make validate

# 4. Deploy
make apply
```

### Modificar Endpoint Existente

```bash
# 1. Localizar e editar
vim openapi/paths/users.json

# 2. Rebuild e deploy
make build-openapi
make apply
```

### Testar API

```bash
# Testar todos os endpoints
make test

# Ver logs
make logs-api
make logs-lambda

# Listar endpoints
make endpoints
```

## 📦 Arquivos Gerados (não versionados)

```
api-gateway/
├── openapi-spec.json           # Gerado por build-openapi.py
├── lambda/authorizer.zip       # Gerado por build-lambda
├── lambda/node_modules/        # Dependências npm
├── .terraform/                 # Estado do Terraform
├── .terraform.lock.hcl         # Lock de providers
└── terraform.tfstate*          # Estado do Terraform
```

## 🎨 Convenções

### Nomenclatura de Arquivos

- **Terraform**: `snake_case.tf`
- **OpenAPI**: `kebab-case.json`
- **Scripts**: `kebab-case.py` ou `.sh`
- **Docs**: `SCREAMING_SNAKE_CASE.md`

### Organização

- **Terraform**: Raiz do projeto
- **OpenAPI**: Pasta `openapi/` (modular)
- **Lambda**: Pasta `lambda/`
- **Scripts**: Pasta `scripts/`
- **Docs**: Pasta `docs/`

### Commits

```
feat(customers): add list vehicles endpoint
fix(auth): correct JWT validation
docs(readme): update deployment steps
refactor(openapi): split into modular structure
```

## 🚀 Comandos Úteis

```bash
# Setup inicial
make setup              # Check deps + init + build

# Build
make build              # Build OpenAPI + Lambda
make build-openapi      # Apenas OpenAPI
make build-lambda       # Apenas Lambda

# Validação
make validate           # Validar tudo
make check-deps         # Verificar dependências

# Deploy
make plan               # Ver mudanças
make apply              # Aplicar mudanças
make deploy             # Alias para apply

# Testes
make test               # Testar endpoints
make endpoints          # Listar endpoints

# Logs
make logs-api           # Logs do API Gateway
make logs-lambda        # Logs do Lambda

# Manutenção
make clean              # Limpar artifacts
make taint-deployment   # Forçar redeploy
make destroy            # Destruir recursos

# Informações
make help               # Ver todos os comandos
make output             # Ver outputs do Terraform
make docs               # Listar documentação
make cost-estimate      # Estimar custos
```

## 🔍 Localização Rápida

### Preciso modificar...

| O que                       | Onde                                 |
| --------------------------- | ------------------------------------ |
| Endpoint existente          | `openapi/paths/{module}.json`        |
| Configuração base da API    | `openapi/base.json`                  |
| Lambda authorizer           | `lambda/index.js`                    |
| Variáveis do Terraform      | `variables.tf` ou `terraform.tfvars` |
| Configuração do API Gateway | `main.tf`                            |
| Documentação                | `docs/{topic}.md`                    |

### Preciso entender...

| O que                     | Onde                                 |
| ------------------------- | ------------------------------------ |
| Como começar              | `README.md` ou `docs/QUICK_START.md` |
| Arquitetura               | `docs/ARCHITECTURE.md`               |
| Como fazer deploy         | `docs/DEPLOYMENT.md`                 |
| Como integrar com infra   | `docs/INTEGRATION.md`                |
| Referência de endpoints   | `docs/ENDPOINTS.md`                  |
| Estrutura do projeto      | `docs/PROJECT_STRUCTURE.md`          |
| Estrutura modular OpenAPI | `openapi/README.md`                  |
| Histórico de mudanças     | `docs/CHANGELOG.md`                  |

## ✅ Checklist de Manutenção

### Ao adicionar endpoint

- [ ] Editar arquivo correto em `openapi/paths/`
- [ ] Executar `make build-openapi`
- [ ] Executar `make validate`
- [ ] Executar `make plan`
- [ ] Executar `make apply`
- [ ] Testar endpoint com `make test`
- [ ] Atualizar `docs/ENDPOINTS.md` se necessário
- [ ] Commit com mensagem descritiva

### Ao modificar Lambda

- [ ] Editar `lambda/index.js`
- [ ] Executar `make build-lambda`
- [ ] Executar `make apply`
- [ ] Verificar logs com `make logs-lambda`
- [ ] Testar autenticação
- [ ] Commit com mensagem descritiva

### Ao atualizar documentação

- [ ] Editar arquivo em `docs/`
- [ ] Verificar links internos
- [ ] Atualizar `docs/CHANGELOG.md`
- [ ] Commit com mensagem descritiva

## 🎉 Benefícios da Estrutura Atual

### ✅ Organização

- Documentação centralizada em `docs/`
- OpenAPI modular em `openapi/paths/`
- Scripts de automação em `scripts/`
- Separação clara de responsabilidades

### ✅ Manutenibilidade

- Arquivos pequenos e focados
- Fácil localização de código
- Build automatizado
- Validação integrada

### ✅ Colaboração

- Múltiplos devs podem trabalhar simultaneamente
- Menos conflitos de merge
- Code review focado por módulo
- Documentação sempre atualizada

### ✅ Escalabilidade

- Fácil adicionar novos módulos
- Estrutura suporta crescimento
- Performance consistente
- Padrões bem definidos

---

**Estrutura limpa e organizada! 🚀**

Para começar, veja: [README.md](README.md) ou [docs/QUICK_START.md](docs/QUICK_START.md)

# GitHub Actions Workflows

Este diretório contém os workflows de CI/CD para o API Gateway.

## Workflows Disponíveis

### 1. CI (`ci.yml`)

**Trigger:** Pull requests e pushes para `develop` e `main`

**Jobs:**

- `validate-terraform`: Valida configuração Terraform
  - Build do OpenAPI spec
  - Build dos pacotes Lambda
  - Terraform fmt check
  - Terraform validate
- `validate-openapi`: Valida especificação OpenAPI
  - Build do OpenAPI spec
  - Validação JSON
  - Upload do artifact
- `test-lambda`: Testa funções Lambda
  - Executa testes unitários (quando disponíveis)
- `lint-lambda`: Lint do código Lambda
  - ESLint (quando configurado)
- `security-scan`: Scan de segurança
  - npm audit
  - Trivy security scan

### 2. Deploy (`deploy.yml`)

**Trigger:**

- Pull requests fechados (merged) de branches `release/*` para `main`
- Workflow manual (`workflow_dispatch`)

**Stages:**

#### Stage 1: Build & Validate

- Extrai versão do release
- **Build do OpenAPI spec** (CRÍTICO)
- Build dos pacotes Lambda
- Upload de artifacts

#### Stage 2: Deploy Lambda Functions (~4 min)

- **Build do OpenAPI spec** (necessário para Terraform locals)
- Build dos pacotes Lambda
- Deploy apenas das Lambdas usando `terraform apply -target`
- Otimizado para rodar em paralelo

#### Stage 3: Deploy API Gateway (~30 seg)

- **Build do OpenAPI spec**
- Deploy do API Gateway e permissões
- Usa ARNs das Lambdas criadas no Stage 2
- Exibe endpoint da API

#### Stage 4: Deploy Infrastructure (Legacy)

- Desabilitado (`if: false`)
- Mantido para compatibilidade
- Use Stages 2 e 3 em vez deste

#### Stage 5: Update Lambda Code (Optional)

- Desabilitado (`if: false`)
- Lambdas já são criadas no Stage 2
- Mantido para referência futura

#### Stage 6: Integration Tests

- Testa health do API Gateway
- Executa testes de endpoints
- Testa fluxo de autenticação

#### Stage 7: Deployment Summary

- Gera resumo do deployment
- Exibe endpoint da API
- Mostra comandos de teste

### 3. Release (`release.yml`)

**Trigger:** Workflow manual

**Jobs:**

- Cria branch de release
- Atualiza CHANGELOG
- Cria pull request para `main`

## Variáveis de Ambiente

### Secrets Necessários

- `AWS_ACCESS_KEY_ID`: Credenciais AWS
- `AWS_SECRET_ACCESS_KEY`: Credenciais AWS
- `AWS_SESSION_TOKEN`: Token de sessão AWS (AWS Academy)
- `JWT_SECRET_KEY`: Chave secreta para JWT
- `ALB_ENDPOINT`: Endpoint do ALB backend
- `DB_PASSWORD`: Senha do banco de dados

### Variáveis de Ambiente

- `AWS_REGION`: Região AWS (padrão: `us-east-1`)

## Build do OpenAPI Spec

**CRÍTICO:** O arquivo `openapi-spec.json` DEVE ser gerado antes de qualquer operação Terraform.

### Por que é necessário?

O Terraform usa `file("${path.module}/openapi-spec.json")` no `main.tf`, que requer que o arquivo exista no momento da execução.

### Onde é executado?

O build do OpenAPI é executado em TODOS os stages que usam Terraform:

1. ✅ Stage 1: Build & Validate
2. ✅ Stage 2: Deploy Lambda Functions
3. ✅ Stage 3: Deploy API Gateway
4. ✅ CI: Validate Terraform
5. ✅ CI: Validate OpenAPI

### Como funciona?

```bash
pip install pyyaml
python scripts/build-openapi.py
```

O script:

1. Lê `openapi/base.json`
2. Mescla todos os arquivos em `openapi/paths/*.json`
3. Gera `openapi-spec.json` consolidado
4. Valida JSON

## Otimizações de Performance

### Deploy Separado (Stages 2 e 3)

**Antes:** Deploy monolítico (~5 min)

- Lambdas + API Gateway juntos
- Falha em qualquer componente = rollback completo

**Depois:** Deploy em etapas (~4.5 min)

- Stage 2: Lambdas (~4 min devido à VPC)
- Stage 3: API Gateway (~30 seg)
- Falhas isoladas por componente
- Melhor visibilidade do progresso

### Benefícios

1. **Paralelização**: Stages podem rodar em paralelo quando possível
2. **Rollback granular**: Reverter apenas o componente com problema
3. **Debugging facilitado**: Erros isolados por stage
4. **Visibilidade**: Progresso claro de cada componente

## Inputs do Workflow Manual

### `skip_lambda`

- **Tipo:** Boolean
- **Padrão:** `false`
- **Descrição:** Pula atualização de código Lambda (Stage 5)
- **Uso:** Quando apenas o API Gateway mudou

### `environment`

- **Tipo:** Choice
- **Opções:** `production`, `staging`
- **Padrão:** `production`
- **Descrição:** Ambiente de deployment

## Troubleshooting

### Erro: "no file exists at ./openapi-spec.json"

**Causa:** Build do OpenAPI não foi executado
**Solução:** Verificar se o step "Build OpenAPI Spec" está presente e executando

### Erro: "Invalid function ARN or invalid uri"

**Causa:** Lambdas não foram criadas antes do API Gateway
**Solução:** Usar Stages 2 e 3 separados (já implementado)

### Erro: "Invalid mapping expression parameter"

**Causa:** `requestParameters` com Authorization header em `http_proxy`
**Solução:** Remover `requestParameters` (já corrigido)

### Lambdas demoram ~4 minutos

**Causa:** VPC attachment leva tempo
**Solução:** Normal, otimizado com deploy separado

## Manutenção

### Adicionar novo endpoint

1. Criar/editar arquivo em `openapi/paths/`
2. Commit e push
3. CI valida automaticamente
4. Deploy via workflow manual ou merge de release

### Atualizar Lambda

1. Editar código em `lambda/` ou `lambda/auth/`
2. Commit e push
3. CI testa automaticamente
4. Deploy via workflow manual ou merge de release

### Criar nova release

1. Executar workflow `release.yml`
2. Revisar PR criado
3. Merge para `main`
4. Deploy automático via `deploy.yml`

## Monitoramento

### Logs do Workflow

- GitHub Actions > Workflow run > Job > Step

### Logs da API

```bash
# API Gateway logs
make logs-api

# Lambda authorizer logs
make logs-lambda

# Lambda auth logs
make logs-lambda-auth
```

### Métricas

- CloudWatch > API Gateway > Metrics
- CloudWatch > Lambda > Metrics

## Referências

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [API Gateway Extensions](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html)
- [GitHub Actions](https://docs.github.com/en/actions)

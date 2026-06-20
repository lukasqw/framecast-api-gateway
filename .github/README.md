# CI/CD Workflows — framecast-gateway

## Fluxo geral

```
push to develop (terraform/** openapi/** scripts/**)
      │
      ▼
  [release.yml] ──── PR existe? ────► update-pr (sync + changelog)
                          │
                          NO
                          ▼
                     create-pr (versão + branch + draft PR)
                          │
      merge PR to main ◄──┘
              │
              ▼
         [deploy.yml]
              │
              ▼
         deploy job
    (build → tf-apply → api-check → create-release)
              │
              ▼
         tag + GitHub Release
```

## Workflows

| Workflow | Trigger | Descrição |
|---|---|---|
| `ci.yml` | PR para `develop`/`main` (paths: terraform/\*\*, openapi/\*\*, scripts/\*\*), push em `develop` | Build OpenAPI → validate → security scan → terraform plan |
| `release.yml` | Push em `develop` (paths acima), `workflow_dispatch` | Cria ou atualiza PR de release |
| `deploy.yml` | PR de `release/*` mergeado em `main`, `workflow_dispatch` | Build → Terraform apply → health check → release |
| `destroy.yml` | `workflow_dispatch` (confirmação manual) | Build spec + Terraform destroy |
| `rollback.yml` | `workflow_dispatch` (versão + ambiente) | Build spec da tag + Terraform apply sem nova tag |

## Composite Actions

```
.github/actions/
├── build/
│   └── openapi/        Python + build-openapi-consolidated.py → openapi-spec.json
├── ci/
│   ├── tf-validate/    fmt check + terraform init (sem backend) + validate
│   ├── tf-security/    tfsec + checkov + upload SARIF
│   ├── tf-plan/        terraform plan + upload artifact + comentário no PR
│   └── tf-structure/   verifica arquivos obrigatórios e estrutura de módulos
├── release/
│   ├── create-pr/      Calcula versão (conventional commits), cria branch e draft PR
│   ├── update-pr/      Sincroniza branch de release com develop e atualiza changelog
│   └── finalize-tag/   (usado internamente pelo create-release)
└── deploy/
    ├── tf-apply/       init + plan/artifact reuse + show + apply + API GW outputs
    ├── api-check/      Probe HTTP no API Gateway com retry (5×, 30s)
    └── create-release/ git tag anotada + GitHub Release com links e endpoint
```

**Não há `build/lambda`** — o gateway não tem Lambda. Auth JWT é responsabilidade exclusiva da `framecast-api`.

## Configuração no repositório

Configure em **Settings → Secrets and Variables → Variables / Secrets**.
Veja [`variables.env.example`](variables.env.example) para a lista completa.

### Variáveis obrigatórias

| Variável | Valor esperado |
|---|---|
| `AWS_REGION` | `us-east-1` |
| `TF_VERSION` | `1.7.0` |
| `TF_WORKING_DIR` | `terraform/environments/production` |
| `TF_STATE_BUCKET` | `fiap-soat-tf-backend-framecast` |
| `HEALTH_ENDPOINT` | `/health` |

### Secrets obrigatórios

| Secret | Descrição |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS |
| `AWS_SESSION_TOKEN` | Sessão temporária (AWS Academy / LabRole) |

**Não há `JWT_SECRET_KEY` nem `DB_PASSWORD`** — o gateway não acessa banco e não assina JWT.

### Variáveis opcionais (via `terraform.tfvars` ou `TF_VAR_*`)

| Variável | Padrão | Descrição |
|---|---|---|
| `enable_waf` | `true` | Desativar se LabRole não tem `wafv2:*` |
| `enable_vpc_link` | `true` | `false` em dev/LocalStack |
| `waf_rate_limit` | `2000` | Req/5min/IP antes de bloquear |
| `framecast_api_endpoint` | `""` | Override do NLB DNS (vazio = derivado do remote state) |

## Versionamento

Versão calculada automaticamente via [Conventional Commits](https://www.conventionalcommits.org):

| Padrão de commit | Bump |
|---|---|
| `feat!:` ou `BREAKING CHANGE:` no corpo | `major` |
| `feat:` | `minor` |
| `fix:`, `chore:`, `docs:`, … | `patch` |

Tags seguem o padrão `v1.2.3` (sem prefixo de serviço — repositórios têm namespaces de tags independentes).

## Tag e GitHub Release

A tag e o GitHub Release são criados **após** o `api-check` confirmar que o API Gateway está respondendo em `/health`. O `workflow_dispatch` redeploya a versão existente sem criar nova tag.

## Notas de deploy

- **VPC Link:** criação/atualização pode levar vários minutos — pipeline com `timeout-minutes: 45`.
- **WAF Academy:** se a LabRole não tiver `wafv2:*`, definir `TF_VAR_enable_waf=false` antes do apply.
- **State sem lock:** `concurrency: deploy` no workflow — nunca executar applies paralelos.
- **Pré-requisito:** `framecast-infra` deve estar aplicado (provê `nlb_arn` e `nlb_dns_name` via remote state).

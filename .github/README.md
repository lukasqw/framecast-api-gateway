# CI/CD Workflows

## Fluxo geral

```
push to develop (terraform/** lambda/** openapi/** scripts/**)
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
    (build → tf-apply → api-check → integration tests → create-release)
              │
              ▼
         tag + GitHub Release
```

## Workflows

| Workflow | Trigger | Descrição |
|---|---|---|
| `ci.yml` | PR para `develop`/`main` (paths: terraform/\*\*, lambda/\*\*, openapi/\*\*, scripts/\*\*), push em `develop` | Build → validate → security scan + terraform plan + lambda quality |
| `release.yml` | Push em `develop` (paths acima), `workflow_dispatch` | Cria ou atualiza PR de release |
| `deploy.yml` | PR de `release/*` mergeado em `main`, `workflow_dispatch` | Build → Terraform apply → health check → integration tests → release |
| `destroy.yml` | `workflow_dispatch` (confirmação manual) | Build artefatos + Terraform destroy |
| `rollback.yml` | `workflow_dispatch` (versão + ambiente) | Build artefatos da tag + Terraform apply; sem criar nova tag |

## Composite Actions

```
.github/actions/
├── build/
│   ├── openapi/        Python + build-openapi-consolidated.py → openapi-spec.json
│   └── lambda/         npm ci --production + zip → lambda/auth.zip
├── ci/
│   ├── tf-validate/    fmt check + terraform init (sem backend) + validate  ← verbatim
│   ├── tf-security/    tfsec + checkov + upload SARIF                        ← verbatim
│   ├── tf-plan/        terraform plan + upload artifact + comentário no PR  ← + jwt_secret
│   └── tf-structure/   verifica arquivos obrigatórios e estrutura de módulos ← verbatim
├── release/                                                                   ← verbatim
│   ├── create-pr/      Calcula versão (conventional commits), cria branch e draft PR
│   ├── update-pr/      Sincroniza branch de release com develop e atualiza changelog
│   └── finalize-tag/   (usado internamente pelo create-release)
└── deploy/
    ├── tf-apply/       init + plan/artifact reuse + show + apply + API GW outputs
    ├── api-check/      Probe HTTP no API Gateway com retry (5x, 30s)
    └── create-release/ git tag anotada + GitHub Release com links e endpoint
```

## Configuração por repositório

Todos os valores específicos são configurados em **Settings → Secrets and Variables → Variables**.
Veja [`variables.env.example`](variables.env.example) para a lista completa.

### Variáveis obrigatórias

| Variável | Descrição |
|---|---|
| `AWS_REGION` | Região AWS |
| `TF_VERSION` | Versão do Terraform (ex: `1.7.0`) |
| `TF_WORKING_DIR` | Caminho do módulo Terraform (padrão: `.`) |
| `HEALTH_ENDPOINT` | Endpoint do health check (ex: `/health`) |

### Secrets obrigatórios

| Secret | Descrição |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS |
| `AWS_SESSION_TOKEN` | Credencial AWS (sessão temporária) |
| `JWT_SECRET_KEY` | Segredo de assinatura JWT (`TF_VAR_jwt_secret`) |
| `DB_PASSWORD` | Senha do banco de dados (`TF_VAR_db_password`) |

## Versionamento

Idêntico aos outros repos — versão calculada automaticamente via [Conventional Commits](https://www.conventionalcommits.org):

| Padrão de commit | Bump |
|---|---|
| `feat!:` ou `BREAKING CHANGE:` no corpo | `major` |
| `feat:` | `minor` |
| Qualquer outro (`fix:`, `chore:`, `docs:`, …) | `patch` |

> **Nota:** O prefixo `gateway-v` foi removido. Tags agora seguem o padrão `v1.2.3`
> igual aos outros repositórios — não há conflito pois tags são por repositório.

## Tag e GitHub Release

A tag e o GitHub Release são criados **após** o `api-check` confirmar que o API Gateway está respondendo — mesmo padrão dos outros repos. O `workflow_dispatch` redeploya a versão existente sem criar nova tag.

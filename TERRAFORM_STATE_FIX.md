# Fix: API Gateway sendo criado a cada deploy

## Problemas Resolvidos

### 1. API Gateway Duplicado

- ❌ **Antes**: Novo API Gateway criado a cada deploy
- ✅ **Depois**: Mesmo API Gateway reutilizado e atualizado

### 2. Conflitos de Lambda

- ❌ **Antes**: Erro "função já existe", necessário script de limpeza
- ✅ **Depois**: Lambdas são atualizadas automaticamente pelo Terraform

### 3. Deploy Mais Rápido

- ❌ **Antes**: ~8-10 minutos (criação completa + limpeza)
- ✅ **Depois**: ~3-5 minutos (apenas atualizações necessárias)

## Causa Raiz

O Terraform estava usando **estado local** (`terraform.tfstate` no repositório) em vez de um **backend remoto**. Isso significa que:

1. A GitHub Action executa em um ambiente limpo a cada run
2. O arquivo de estado local não está disponível
3. O Terraform não consegue identificar recursos existentes
4. Todos os recursos são tratados como novos

## Solução Implementada

### 1. Configuração de Backend Remoto

Adicionado backend S3 no `main.tf`:

```hcl
backend "s3" {
  bucket = "fiap-soat-tf-backend-bispo-730335587750"
  key    = "fiap/api-gateway/terraform.tfstate"
  region = "us-east-1"
}
```

### Estrutura de Estados no S3

```
fiap-soat-tf-backend-bispo-730335587750/
├── fiap/terraform.tfstate              # Infraestrutura principal (VPC, RDS, etc.)
└── fiap/api-gateway/terraform.tfstate  # API Gateway e Lambdas
```

### 2. Migração Automática de Estado

Adicionado step no workflow para migrar o estado local existente:

```yaml
- name: Migrate State to Remote Backend (if needed)
  run: |
    if [ -f "terraform.tfstate" ] && [ -s "terraform.tfstate" ]; then
      echo "::notice::Migrating local state to remote backend..."
      terraform init -migrate-state -force-copy
    fi
```

### 3. Benefícios da Separação de Estados

- ✅ **Isolamento**: API Gateway pode ser deployado independentemente da infraestrutura principal
- ✅ **Segurança**: Mudanças no API Gateway não afetam VPC, RDS, etc.
- ✅ **Flexibilidade**: Diferentes equipes podem gerenciar diferentes componentes
- ✅ **Rollback**: Possível fazer rollback apenas do API Gateway se necessário
- ✅ **Performance**: Estados menores = operações mais rápidas
- ✅ **Estado compartilhado**: Recursos existentes são reutilizados entre deploys

## Próximos Passos

1. **Primeira execução**: O workflow irá migrar automaticamente o estado local para o backend remoto
2. **Execuções subsequentes**: O Terraform usará o estado remoto e não criará recursos duplicados
3. **Limpeza**: Após confirmar que tudo funciona, o arquivo `terraform.tfstate` local pode ser removido

## Verificação

Para verificar se a solução funcionou:

1. Execute o workflow
2. Verifique nos logs se aparece "State migration completed"
3. Execute novamente - não deve criar novos recursos
4. Confirme que o mesmo API Gateway ID é reutilizado

## Arquivos Modificados

- `main.tf` - Adicionado backend S3 remoto
- `.github/workflows/deploy.yml` - Adicionado migração de estado e **removido** step de limpeza de Lambdas
- `TERRAFORM_STATE_FIX.md` - Esta documentação

## Scripts Não Mais Necessários

- `scripts/clean-existing-lambdas.sh` - Pode ser mantido para casos de emergência, mas não é mais executado automaticamente

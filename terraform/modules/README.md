# Terraform Modules

Este diretório contém módulos Terraform reutilizáveis para o projeto Oficina Tech API Gateway.

## 📁 Estrutura

```
modules/
├── api-gateway/          # Módulo do API Gateway
│   ├── main.tf          # Recursos principais
│   ├── variables.tf     # Variáveis de entrada
│   └── outputs.tf       # Outputs do módulo
└── lambda/              # Módulo Lambda
    ├── main.tf          # Recursos principais
    ├── variables.tf     # Variáveis de entrada
    └── outputs.tf       # Outputs do módulo
```

## 🔧 Módulos Disponíveis

### 1. API Gateway Module

Cria e configura um API Gateway REST API completo com:

- OpenAPI specification
- Stage e deployment
- Usage plans e rate limiting
- API Keys (opcional)
- Custom domain (opcional)
- Cache (opcional)
- Logging

**Uso:**

```hcl
module "api_gateway" {
  source = "./terraform/modules/api-gateway"

  api_name        = "my-api"
  api_description = "My API description"
  openapi_spec    = local.openapi_spec
  stage_name      = "v1"

  enable_logging = true
  enable_cache   = false

  throttle_burst_limit = 5000
  throttle_rate_limit  = 10000

  tags = {
    Environment = "dev"
  }
}
```

### 2. Lambda Module

Cria e configura uma função Lambda com:

- VPC configuration (opcional)
- Environment variables
- API Gateway permission
- Tags

**Uso:**

```hcl
module "lambda_auth" {
  source = "./terraform/modules/lambda"

  filename      = "lambda/auth.zip"
  function_name = "my-auth-function"
  role_arn      = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  environment_variables = {
    DB_HOST = "localhost"
  }

  vpc_subnet_ids         = ["subnet-xxx"]
  vpc_security_group_ids = ["sg-xxx"]

  tags = {
    Environment = "dev"
  }
}
```

## 📝 Benefícios dos Módulos

1. **Reutilização**: Use os mesmos módulos em múltiplos ambientes
2. **Manutenibilidade**: Mudanças em um lugar afetam todos os usos
3. **Testabilidade**: Teste módulos independentemente
4. **Documentação**: Cada módulo é auto-documentado
5. **Versionamento**: Versione módulos separadamente

## 🎯 Boas Práticas

- Sempre use variáveis para valores configuráveis
- Documente todas as variáveis e outputs
- Use valores padrão sensatos
- Valide inputs quando possível
- Use tags consistentes
- Mantenha módulos focados e coesos

## 🔄 Atualizando Módulos

Quando atualizar um módulo:

1. Teste as mudanças localmente
2. Atualize a documentação
3. Verifique compatibilidade retroativa
4. Execute `terraform plan` em todos os ambientes
5. Aplique mudanças gradualmente

## 📚 Documentação Adicional

- [Terraform Module Documentation](https://www.terraform.io/docs/language/modules/index.html)
- [Module Best Practices](https://www.terraform.io/docs/language/modules/develop/index.html)

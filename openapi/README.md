# OpenAPI Modular Structure

Esta estrutura modular facilita a manutenção da especificação OpenAPI, dividindo-a em arquivos menores e mais gerenciáveis.

## 📁 Estrutura

```
openapi/
├── README.md              # Este arquivo
├── base.json              # Configuração base (info, servers, components)
└── paths/                 # Definições de endpoints por módulo
    ├── auth.json          # Autenticação (1 endpoint)
    ├── users.json         # Usuários (4 endpoints)
    ├── customers.json     # Clientes (5 endpoints)
    ├── vehicles.json      # Veículos (5 endpoints)
    ├── services.json      # Serviços (5 endpoints)
    ├── products.json      # Produtos (4 endpoints)
    ├── inventory.json     # Inventário (7 endpoints)
    └── service-orders.json # Ordens de serviço (7 endpoints)
```

## 🔨 Build

Para gerar o arquivo `openapi-spec.json` consolidado:

```bash
# Usando Make
make build-openapi

# Ou diretamente
python3 scripts/build-openapi.py
```

O script irá:

1. Ler `base.json` com configurações gerais
2. Mesclar todos os arquivos em `paths/`
3. Gerar `openapi-spec.json` na raiz do projeto
4. Validar o JSON gerado

## ✏️ Adicionar Novo Endpoint

### 1. Escolher o Arquivo Correto

Adicione o endpoint no arquivo correspondente ao módulo:

- **Autenticação** → `paths/auth.json`
- **Usuários** → `paths/users.json`
- **Clientes** → `paths/customers.json`
- **Veículos** → `paths/vehicles.json`
- **Serviços** → `paths/services.json`
- **Produtos** → `paths/products.json`
- **Inventário** → `paths/inventory.json`
- **Ordens de Serviço** → `paths/service-orders.json`

### 2. Adicionar Definição

Exemplo de endpoint protegido com path parameter:

```json
{
  "/seu-recurso/{id}": {
    "get": {
      "summary": "Descrição curta",
      "description": "Descrição detalhada do endpoint",
      "tags": ["nome-do-modulo"],
      "responses": {
        "200": { "description": "Success" },
        "400": { "description": "Bad Request" },
        "401": { "description": "Unauthorized" },
        "404": { "description": "Not Found" },
        "500": { "description": "Internal Server Error" }
      },
      "security": [{ "BearerAuth": [] }],
      "parameters": [
        {
          "name": "id",
          "in": "path",
          "required": true,
          "schema": { "type": "string" }
        }
      ],
      "x-amazon-apigateway-integration": {
        "type": "http_proxy",
        "httpMethod": "GET",
        "uri": "${alb_endpoint}/seu-recurso/{id}",
        "passthroughBehavior": "when_no_match",
        "requestParameters": {
          "integration.request.path.id": "method.request.path.id",
          "integration.request.header.Authorization": "method.request.header.Authorization"
        }
      }
    }
  }
}
```

### 3. Rebuild

```bash
make build-openapi
```

### 4. Deploy

```bash
make apply
```

## 📝 Padrões de Endpoint

### Endpoint Público (sem autenticação)

```json
{
  "/public-endpoint": {
    "post": {
      "summary": "Public endpoint",
      "tags": ["module"],
      "responses": {
        "200": { "description": "Success" }
      },
      "x-amazon-apigateway-integration": {
        "type": "http_proxy",
        "httpMethod": "POST",
        "uri": "${alb_endpoint}/public-endpoint",
        "passthroughBehavior": "when_no_match"
      }
    }
  }
}
```

### Endpoint Protegido (requer JWT)

```json
{
  "/protected-endpoint": {
    "get": {
      "summary": "Protected endpoint",
      "tags": ["module"],
      "security": [{ "BearerAuth": [] }],
      "responses": {
        "200": { "description": "Success" }
      },
      "x-amazon-apigateway-integration": {
        "type": "http_proxy",
        "httpMethod": "GET",
        "uri": "${alb_endpoint}/protected-endpoint",
        "passthroughBehavior": "when_no_match",
        "requestParameters": {
          "integration.request.header.Authorization": "method.request.header.Authorization"
        }
      }
    }
  }
}
```

### Com Path Parameter

```json
{
  "/resource/{id}": {
    "get": {
      "summary": "Get by ID",
      "tags": ["module"],
      "security": [{ "BearerAuth": [] }],
      "parameters": [
        {
          "name": "id",
          "in": "path",
          "required": true,
          "schema": { "type": "string" }
        }
      ],
      "responses": {
        "200": { "description": "Success" }
      },
      "x-amazon-apigateway-integration": {
        "type": "http_proxy",
        "httpMethod": "GET",
        "uri": "${alb_endpoint}/resource/{id}",
        "passthroughBehavior": "when_no_match",
        "requestParameters": {
          "integration.request.path.id": "method.request.path.id",
          "integration.request.header.Authorization": "method.request.header.Authorization"
        }
      }
    }
  }
}
```

### Com Query Parameter

```json
{
  "/resources": {
    "get": {
      "summary": "List with filter",
      "tags": ["module"],
      "security": [{ "BearerAuth": [] }],
      "parameters": [
        {
          "name": "filter",
          "in": "query",
          "required": false,
          "schema": { "type": "string" }
        }
      ],
      "responses": {
        "200": { "description": "Success" }
      },
      "x-amazon-apigateway-integration": {
        "type": "http_proxy",
        "httpMethod": "GET",
        "uri": "${alb_endpoint}/resources",
        "passthroughBehavior": "when_no_match",
        "requestParameters": {
          "integration.request.header.Authorization": "method.request.header.Authorization"
        }
      }
    }
  }
}
```

## 🔧 Modificar Configuração Base

Para alterar configurações globais (info, servers, security schemes), edite `base.json`:

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "${api_title}",
    "description": "Descrição da API",
    "version": "${api_version}"
  },
  "servers": [
    {
      "url": "${alb_endpoint}",
      "description": "Backend endpoint"
    }
  ],
  "components": {
    "securitySchemes": {
      "BearerAuth": {
        "type": "apiKey",
        "name": "Authorization",
        "in": "header",
        "x-amazon-apigateway-authtype": "custom",
        "x-amazon-apigateway-authorizer": {
          "type": "token",
          "authorizerUri": "...",
          "authorizerResultTtlInSeconds": 300,
          "identitySource": "method.request.header.Authorization"
        }
      }
    }
  }
}
```

## ✅ Validação

O script de build valida automaticamente:

- ✓ Sintaxe JSON de cada arquivo
- ✓ Estrutura do OpenAPI gerado
- ✓ Duplicação de paths

Para validar manualmente:

```bash
# Validar JSON
python3 -m json.tool openapi/base.json
python3 -m json.tool openapi/paths/auth.json

# Validar OpenAPI gerado
make validate
```

## 📊 Estatísticas

Após o build, o script mostra:

- Total de paths
- Total de endpoints
- Tamanho do arquivo gerado

Exemplo:

```
Total paths:      21
Total endpoints:  38
File size:        53,470 bytes
```

## 🎯 Benefícios da Estrutura Modular

1. **Manutenção Facilitada**
   - Cada módulo em seu próprio arquivo
   - Fácil localizar e modificar endpoints
   - Menos conflitos em Git

2. **Organização Clara**
   - Estrutura espelha os módulos do backend
   - Separação lógica por domínio
   - Fácil navegação

3. **Colaboração**
   - Múltiplos desenvolvedores podem trabalhar simultaneamente
   - Menos merge conflicts
   - Code review mais focado

4. **Reutilização**
   - Padrões consistentes entre módulos
   - Fácil copiar/adaptar endpoints similares
   - Templates claros

5. **Validação**
   - Erros localizados em arquivos específicos
   - Build falha rápido se houver problemas
   - Feedback claro sobre o que está errado

## 🚨 Regras Importantes

1. **Não edite `openapi-spec.json` diretamente**
   - Sempre edite os arquivos em `openapi/`
   - O arquivo gerado é sobrescrito no build

2. **Sempre rebuild após mudanças**

   ```bash
   make build-openapi
   ```

3. **Valide antes de commitar**

   ```bash
   make validate
   ```

4. **Mantenha consistência**
   - Use os mesmos padrões de response
   - Siga a estrutura de integração
   - Mantenha tags consistentes

5. **Documente bem**
   - `summary`: Descrição curta e clara
   - `description`: Detalhes do comportamento
   - `tags`: Categoria do endpoint

## 🔄 Workflow Completo

```bash
# 1. Editar arquivo do módulo
nano openapi/paths/customers.json

# 2. Build OpenAPI
make build-openapi

# 3. Validar
make validate

# 4. Testar localmente (opcional)
make plan

# 5. Deploy
make apply

# 6. Testar endpoints
make test
```

## 📚 Referências

- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [AWS API Gateway OpenAPI Extensions](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html)
- [JSON Schema](https://json-schema.org/)

## 💡 Dicas

- Use um editor com suporte a JSON Schema para validação em tempo real
- Mantenha os arquivos formatados (2 espaços de indentação)
- Comente mudanças significativas nos commits
- Teste endpoints após cada mudança
- Mantenha backup do `openapi-spec.json` antes de grandes mudanças

---

**Estrutura modular = Manutenção fácil! 🎉**

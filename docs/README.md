# Documentação - Oficina Tech API Gateway

## 📚 Índice de Documentação

### 🚀 Começando

- [QUICK_START.md](QUICK_START.md) - Setup rápido em 5 minutos
- [DEPLOYMENT.md](DEPLOYMENT.md) - Guia completo de deployment

### 🏗️ Arquitetura

- [ARCHITECTURE.md](ARCHITECTURE.md) - Visão geral da arquitetura
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Estrutura do projeto
- [INTEGRATION.md](INTEGRATION.md) - Integração com infraestrutura

### 🔐 Autenticação e Autorização

- [AUTHENTICATION_FLOW.md](AUTHENTICATION_FLOW.md) - **Fluxo completo de autenticação com diagramas**
- [BACKEND_AUTHENTICATION.md](BACKEND_AUTHENTICATION.md) - **Guia completo de implementação no backend**
  - Middleware em Go, Node.js e Python
  - RBAC (Role-Based Access Control)
  - Auditoria e logs
  - Exemplos práticos

### 📖 Referência

- [ENDPOINTS.md](ENDPOINTS.md) - Referência de todos os endpoints
- [CHANGELOG.md](CHANGELOG.md) - Histórico de mudanças

### 🔧 Correções e Troubleshooting

- [../FIX_AUTHORIZER_CONTEXT.md](../FIX_AUTHORIZER_CONTEXT.md) - Correção do erro 500 com authorizer

## 🎯 Guias por Caso de Uso

### Quero entender como funciona a autenticação

1. Leia [AUTHENTICATION_FLOW.md](AUTHENTICATION_FLOW.md) para ver o fluxo completo
2. Veja [BACKEND_AUTHENTICATION.md](BACKEND_AUTHENTICATION.md) para implementar no backend

### Quero fazer deploy

1. Siga [QUICK_START.md](QUICK_START.md) para setup inicial
2. Use [DEPLOYMENT.md](DEPLOYMENT.md) para deploy completo

### Quero adicionar um novo endpoint

1. Leia [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) para entender a estrutura
2. Edite os arquivos em `openapi/paths/`
3. Execute os scripts de build

### Quero integrar com o backend

1. Leia [BACKEND_AUTHENTICATION.md](BACKEND_AUTHENTICATION.md)
2. Implemente o middleware de autenticação
3. Use os headers `X-User-Id`, `X-User-Role`, `X-User-Email`

## 📊 Fluxo de Autenticação Resumido

```
Cliente → API Gateway → Lambda Authorizer → API Gateway → Backend
[JWT]     [Valida]      [Retorna Context]   [Headers]    [Processa]
```

### Headers Injetados pelo API Gateway

O backend recebe automaticamente:

- `X-User-Id` - ID do usuário autenticado
- `X-User-Role` - Role (ADMIN, MANAGER, USER, CUSTOMER)
- `X-User-Email` - Email do usuário

### O Backend NÃO Precisa

- ❌ Validar JWT
- ❌ Verificar assinatura
- ❌ Checar expiração

### O Backend Precisa

- ✅ Ler headers HTTP
- ✅ Implementar lógica de autorização (RBAC)
- ✅ Processar requisição

## 🛠️ Scripts Úteis

```bash
# Adicionar headers do authorizer em todos os endpoints
python3 scripts/add-authorizer-headers.py

# Reconstruir OpenAPI spec
python3 scripts/build-openapi.py

# Build do Lambda
./scripts/build.sh

# Deploy
terraform apply
```

## 📝 Exemplos Rápidos

### Go (Gin)

```go
func GetCustomers(c *gin.Context) {
    userId := c.GetHeader("X-User-Id")
    userRole := c.GetHeader("X-User-Role")

    if userRole != "ADMIN" {
        c.JSON(403, gin.H{"error": "Forbidden"})
        return
    }

    // Processar requisição...
}
```

### Node.js (Express)

```javascript
app.get("/customers", (req, res) => {
  const userId = req.headers["x-user-id"];
  const userRole = req.headers["x-user-role"];

  if (userRole !== "ADMIN") {
    return res.status(403).json({ error: "Forbidden" });
  }

  // Processar requisição...
});
```

### Python (FastAPI)

```python
@app.get("/customers")
async def get_customers(
    x_user_id: str = Header(None),
    x_user_role: str = Header(None)
):
    if x_user_role != "ADMIN":
        raise HTTPException(status_code=403, detail="Forbidden")

    # Processar requisição...
```

## 🔗 Links Externos

- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [AWS API Gateway](https://docs.aws.amazon.com/apigateway/)
- [Lambda Authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)

## 📞 Suporte

Para dúvidas ou problemas:

1. Verifique a documentação relevante acima
2. Consulte [CHANGELOG.md](CHANGELOG.md) para mudanças recentes
3. Revise [../FIX_AUTHORIZER_CONTEXT.md](../FIX_AUTHORIZER_CONTEXT.md) para problemas comuns

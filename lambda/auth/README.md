# Lambda de Autenticação via CPF

Esta Lambda function implementa autenticação via CPF para clientes e usuários do sistema Oficina Tech.

## Funcionalidades

- ✅ Validação de CPF (formato e dígitos verificadores)
- ✅ Consulta de cliente ou usuário no banco de dados PostgreSQL
- ✅ Verificação de senha com bcrypt
- ✅ Verificação de status (ativo/inativo)
- ✅ Geração de token JWT válido por 24 horas
- ✅ Suporte para autenticação de clientes (CPF) e usuários (CPF)

## Endpoint

```
POST /auth/login
```

## Request Body

```json
{
  "cpf": "123.456.789-00",
  "password": "senha123",
  "type": "customer"
}
```

### Parâmetros

- `cpf` (string, obrigatório): CPF com ou sem formatação (pontos e traço)
- `password` (string, obrigatório): Senha do cliente ou usuário
- `type` (string, obrigatório): Tipo de autenticação
  - `"customer"`: Autentica como cliente
  - `"user"`: Autentica como usuário do sistema

## Response

### Sucesso (200 OK)

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "customer",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "João Silva",
    "email": "joao@example.com",
    "cpf": "12345678900",
    "role": "CUSTOMER"
  }
}
```

### Erros

#### 400 Bad Request

```json
{
  "error": "CPF e senha são obrigatórios"
}
```

```json
{
  "error": "Tipo deve ser 'customer' ou 'user'"
}
```

```json
{
  "error": "CPF inválido"
}
```

#### 401 Unauthorized

```json
{
  "error": "Cliente não encontrado"
}
```

```json
{
  "error": "Senha incorreta"
}
```

#### 403 Forbidden

```json
{
  "error": "Cliente inativo"
}
```

#### 500 Internal Server Error

```json
{
  "error": "Erro interno no servidor"
}
```

## Validação de CPF

A função implementa validação completa de CPF:

1. Remove formatação (pontos e traços)
2. Verifica se possui 11 dígitos
3. Verifica se não são todos dígitos iguais (ex: 111.111.111-11)
4. Valida os dois dígitos verificadores usando o algoritmo módulo 11

## Token JWT

O token JWT gerado contém as seguintes claims:

```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "joao@example.com",
  "name": "João Silva",
  "cpf": "12345678900",
  "role": "CUSTOMER",
  "type": "customer",
  "iat": 1234567890,
  "exp": 1234654290
}
```

- Validade: 24 horas
- Algoritmo: HS256
- Secret: Configurado via variável de ambiente `JWT_SECRET`

## Build e Deploy

### 1. Instalar dependências

```bash
cd api-gateway/lambda/auth
npm install
```

### 2. Criar pacote ZIP

```bash
npm run build
```

Isso criará o arquivo `auth.zip` no diretório `api-gateway/lambda/`.

### 3. Deploy com Terraform

```bash
cd api-gateway
terraform init
terraform plan
terraform apply
```

## Variáveis de Ambiente

A Lambda requer as seguintes variáveis de ambiente (configuradas via Terraform):

- `JWT_SECRET`: Chave secreta para assinar tokens JWT (mínimo 32 caracteres)
- `DB_HOST`: Endpoint do RDS PostgreSQL
- `DB_PORT`: Porta do banco de dados (padrão: 5432)
- `DB_USER`: Usuário do banco de dados
- `DB_PASSWORD`: Senha do banco de dados
- `DB_NAME`: Nome do banco de dados
- `DB_SSL`: Habilitar SSL para conexão (`"true"` ou `"false"`)

## Configuração VPC

A Lambda deve estar configurada na mesma VPC do RDS PostgreSQL:

- **Subnets**: Subnets privadas com acesso ao RDS
- **Security Groups**: Deve permitir tráfego de saída para o RDS na porta 5432

## Logs

Os logs são enviados para CloudWatch Logs:

```
/aws/lambda/oficina-tech-cpf-auth-{environment}
```

## Testes

### Teste com curl

```bash
# Autenticação de cliente
curl -X POST https://your-api-gateway.execute-api.us-east-1.amazonaws.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "123.456.789-00",
    "password": "senha123",
    "type": "customer"
  }'

# Autenticação de usuário
curl -X POST https://your-api-gateway.execute-api.us-east-1.amazonaws.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "987.654.321-00",
    "password": "senha456",
    "type": "user"
  }'
```

### Usar o token

```bash
curl -X GET https://your-api-gateway.execute-api.us-east-1.amazonaws.com/v1/customers \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## Segurança

- ✅ Senhas são verificadas com bcrypt (nunca armazenadas em texto plano)
- ✅ Conexão com banco de dados via SSL
- ✅ Lambda executa em VPC privada
- ✅ Tokens JWT com expiração de 24 horas
- ✅ Validação rigorosa de CPF
- ✅ Logs detalhados para auditoria
- ✅ CORS configurado para origens permitidas

## Performance

- **Timeout**: 30 segundos
- **Memory**: 512 MB
- **Connection Pool**: Máximo 10 conexões simultâneas ao banco
- **Cold Start**: ~2-3 segundos
- **Warm Request**: ~100-200ms

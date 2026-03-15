# API Endpoints Reference

Base URL: `https://{api-gateway-id}.execute-api.{region}.amazonaws.com/{stage}`

## Authentication

### POST /auth/login

Login de usuário do sistema

**Authorization:** None (Public)

**Request:**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "role": "ADMIN"
  }
}
```

## Users

### POST /users

Criar novo usuário

**Authorization:** Bearer Token (ADMIN only)

**Request:**

```json
{
  "name": "João Silva",
  "email": "joao@example.com",
  "password": "password123",
  "role": "USER"
}
```

### GET /users

Listar todos os usuários

**Authorization:** Bearer Token (MANAGER, ADMIN)

### GET /users/{id}

Buscar usuário por ID

**Authorization:** Bearer Token (MANAGER, ADMIN, or owner)

### PUT /users/{id}

Atualizar usuário

**Authorization:** Bearer Token (ADMIN or owner)

### DELETE /users/{id}

Deletar usuário

**Authorization:** Bearer Token (ADMIN only)

## Customers

### POST /customers/auth/login

Login de cliente

**Authorization:** None (Public)

### POST /customers/service-orders

Autenticar cliente para ordem de serviço

**Authorization:** None (Public)

### POST /customers/service-orders/respond-authorization

Responder autorização de ordem de serviço

**Authorization:** None (Public)

### POST /customers

Criar cliente

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

**Request:**

```json
{
  "name": "Maria Santos",
  "email": "maria@example.com",
  "phone": "11987654321",
  "document": "12345678900",
  "document_type": "CPF"
}
```

### GET /customers

Listar clientes

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### GET /customers/{id}

Buscar cliente por ID

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### PUT /customers/{id}

Atualizar cliente

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### DELETE /customers/{id}

Deletar cliente

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

## Vehicles

### POST /vehicles

Criar veículo

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

**Request:**

```json
{
  "customer_id": "uuid",
  "plate": "ABC1234",
  "brand": "Toyota",
  "model": "Corolla",
  "year": 2023,
  "color": "Prata"
}
```

### GET /vehicles

Listar veículos

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### GET /vehicles/{id}

Buscar veículo por ID

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### PUT /vehicles/{id}

Atualizar veículo

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### DELETE /vehicles/{id}

Deletar veículo

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

## Services (Catalog)

### POST /services

Criar serviço

**Authorization:** Bearer Token (MANAGER, ADMIN)

**Request:**

```json
{
  "name": "Troca de óleo",
  "description": "Troca de óleo do motor",
  "price": 150.0,
  "estimated_duration_minutes": 30
}
```

### GET /services

Listar serviços

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### GET /services/{id}

Buscar serviço por ID

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### PUT /services/{id}

Atualizar serviço

**Authorization:** Bearer Token (MANAGER, ADMIN)

### DELETE /services/{id}

Deletar serviço

**Authorization:** Bearer Token (MANAGER, ADMIN)

## Service Orders

### POST /service-orders

Criar ordem de serviço

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

**Request:**

```json
{
  "customer_id": "uuid",
  "vehicle_id": "uuid",
  "services": ["service-uuid-1", "service-uuid-2"],
  "description": "Cliente reportou barulho no motor"
}
```

### GET /service-orders

Listar ordens de serviço

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### GET /service-orders/{id}

Buscar ordem de serviço por ID

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### GET /service-orders/{id}/history

Buscar histórico da ordem de serviço

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### PUT /service-orders/{id}

Atualizar ordem de serviço

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### PATCH /service-orders/{id}/advance-status

Avançar status da ordem de serviço

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### DELETE /service-orders/{id}

Deletar ordem de serviço

**Authorization:** Bearer Token (MANAGER, ADMIN)

## Products & Inventory

### POST /products

Criar produto

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

**Request:**

```json
{
  "name": "Óleo 5W30",
  "description": "Óleo sintético para motor",
  "price": 45.0,
  "sku": "OIL-5W30-001"
}
```

### GET /products

Listar produtos

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### GET /products/{product_id}

Buscar produto por ID

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### PUT /products/{product_id}

Atualizar produto

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### DELETE /products/{product_id}

Deletar produto

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### POST /products/{product_id}/inventory

Criar inventário para produto

**Authorization:** Bearer Token (MANAGER, ADMIN)

### GET /products/{product_id}/inventory

Buscar inventário do produto

**Authorization:** Bearer Token (USER, MANAGER, ADMIN)

### DELETE /products/{product_id}/inventory

Deletar inventário

**Authorization:** Bearer Token (MANAGER, ADMIN)

### POST /products/{product_id}/inventory/manual-decrease

Diminuir estoque manualmente

**Authorization:** Bearer Token (MANAGER, ADMIN)

### POST /products/{product_id}/inventory/reserved-decrease

Diminuir estoque reservado

**Authorization:** Bearer Token (MANAGER, ADMIN)

### POST /products/{product_id}/inventory/available-decrease

Diminuir estoque disponível

**Authorization:** Bearer Token (MANAGER, ADMIN)

### POST /products/{product_id}/inventory/reserve

Reservar estoque

**Authorization:** Bearer Token (MANAGER, ADMIN)

### POST /products/{product_id}/inventory/increase

Aumentar estoque

**Authorization:** Bearer Token (MANAGER, ADMIN)

### POST /products/{product_id}/inventory/cancel-reserved

Cancelar reserva

**Authorization:** Bearer Token (MANAGER, ADMIN)

### POST /products/{product_id}/inventory/cancel-confirmed

Cancelar confirmação

**Authorization:** Bearer Token (MANAGER, ADMIN)

## Error Responses

### 400 Bad Request

```json
{
  "error": "Validation error",
  "details": "Invalid email format"
}
```

### 401 Unauthorized

```json
{
  "message": "Unauthorized"
}
```

### 403 Forbidden

```json
{
  "error": "Acesso negado",
  "details": "Usuário não possui permissão para esta operação"
}
```

### 404 Not Found

```json
{
  "error": "Recurso não encontrado"
}
```

### 500 Internal Server Error

```json
{
  "error": "Internal server error"
}
```

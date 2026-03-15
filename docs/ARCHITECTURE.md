# Architecture Overview

## System Architecture

```
┌─────────────┐
│   Client    │
│ (Browser/   │
│   Mobile)   │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────────────────────────────────┐
│         AWS API Gateway                 │
│  ┌───────────────────────────────────┐  │
│  │  REST API (Regional)              │  │
│  │  - 48 endpoints                   │  │
│  │  - CORS enabled                   │  │
│  │  - Request/Response logging       │  │
│  │  - X-Ray tracing                  │  │
│  └───────────────────────────────────┘  │
└──────┬──────────────────────┬───────────┘
       │                      │
       │ Public routes        │ Protected routes
       │ (no auth)            │ (JWT auth)
       │                      │
       │                      ▼
       │              ┌──────────────────┐
       │              │ Lambda Authorizer│
       │              │ - JWT validation │
       │              │ - Role extraction│
       │              └──────────────────┘
       │                      │
       │                      │ IAM Policy
       ▼                      ▼
┌─────────────────────────────────────────┐
│     Application Load Balancer (ALB)     │
│  - Health checks                        │
│  - SSL termination                      │
│  - Target: EKS Service                  │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         EKS Cluster                     │
│  ┌───────────────────────────────────┐  │
│  │  Oficina Tech Backend             │  │
│  │  - Go REST API                    │  │
│  │  - 6 modules                      │  │
│  │  - PostgreSQL                     │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Request Flow

### Public Endpoints (Login)

1. Client sends request to API Gateway
2. API Gateway forwards to ALB
3. ALB routes to backend service
4. Backend validates credentials
5. Backend returns JWT token
6. Response flows back to client

### Protected Endpoints

1. Client sends request with JWT token
2. API Gateway invokes Lambda Authorizer
3. Lambda validates JWT and extracts claims
4. Lambda returns IAM policy (Allow/Deny)
5. If allowed, API Gateway forwards to ALB
6. ALB routes to backend service
7. Backend processes request with user context
8. Response flows back to client

## Module Structure

```
api-gateway/
├── main.tf                 # Main API Gateway configuration
├── authorizer.tf           # Lambda authorizer setup
├── cors.tf                 # CORS configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── lambda/                 # Lambda authorizer code
│   ├── index.js           # JWT validation logic
│   ├── package.json       # Dependencies
│   └── README.md          # Lambda documentation
└── modules/               # Route modules
    ├── auth/              # Authentication routes
    ├── users/             # User management routes
    ├── customers/         # Customer routes
    ├── vehicles/          # Vehicle routes
    ├── services/          # Service catalog routes
    ├── service_orders/    # Service order routes
    └── products/          # Product & inventory routes
```

## Security Layers

### 1. API Gateway Level

- HTTPS only
- Request throttling (10,000 req/s)
- Burst limit (5,000 requests)
- IP whitelisting (optional)
- API keys (optional)

### 2. Lambda Authorizer

- JWT signature validation
- Token expiration check
- Role extraction
- IAM policy generation
- 5-minute cache TTL

### 3. Backend Level

- RBAC middleware
- Owner-based access control
- Domain-level validation
- SQL injection prevention (GORM)

## Monitoring & Logging

### CloudWatch Logs

- API Gateway access logs
- Lambda authorizer execution logs
- Request/response payloads (configurable)

### CloudWatch Metrics

- Request count by endpoint
- Latency (p50, p90, p99)
- Error rates (4XX, 5XX)
- Authorizer cache hit rate

### X-Ray Tracing

- End-to-end request tracing
- Service map visualization
- Performance bottleneck identification

## High Availability

### API Gateway

- Regional deployment
- Multi-AZ by default
- 99.95% SLA

### Lambda Authorizer

- Automatic scaling
- Multi-AZ execution
- Result caching (5 minutes)

### ALB

- Multi-AZ deployment
- Health checks
- Auto-scaling target groups

## Performance Optimization

### Caching

- Lambda authorizer results: 5 minutes
- Reduces authorization latency
- Configurable TTL

### Connection Reuse

- HTTP keep-alive to ALB
- Connection pooling

### Throttling

- Protects backend from overload
- Configurable limits per stage

## Cost Optimization

### API Gateway

- Pay per request model
- No minimum fees
- Free tier: 1M requests/month (12 months)

### Lambda

- Pay per invocation
- 1M free requests/month
- 400,000 GB-seconds free/month

### Data Transfer

- In: Free
- Out: $0.09/GB after 1GB free

## Disaster Recovery

### Backup Strategy

- Terraform state in S3 (recommended)
- Lambda code in version control
- Configuration as code

### Recovery Procedure

1. Restore Terraform state
2. Run `terraform apply`
3. Verify endpoints
4. Update DNS if needed

### RTO/RPO

- RTO: < 30 minutes
- RPO: 0 (infrastructure as code)

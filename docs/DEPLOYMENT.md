# Deployment Guide

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. Node.js >= 20.x installed (for Lambda build)
4. Backend ALB endpoint available
5. JWT secret key (must match backend)

## Step-by-Step Deployment

### 1. Configure Variables

Copy the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region  = "us-east-1"
environment = "production"
stage_name  = "v1"

# Your ALB endpoint from EKS infrastructure
alb_endpoint = "https://your-alb-endpoint.us-east-1.elb.amazonaws.com"

# JWT secret (must match backend JWT_SECRET_KEY)
jwt_secret = "your-jwt-secret-key-32-characters-minimum"

# CORS origins
allowed_origins = [
  "https://yourdomain.com",
  "https://www.yourdomain.com"
]
```

### 2. Build Lambda Authorizer

```bash
make build-lambda
```

Or manually:

```bash
cd lambda
npm install
npm run build
cd ..
```

### 3. Initialize Terraform

```bash
make init
```

Or:

```bash
terraform init
```

### 4. Review Plan

```bash
make plan
```

Review the resources that will be created:

- API Gateway REST API
- 48 API Gateway methods (routes)
- Lambda authorizer function
- IAM roles and policies
- CloudWatch log groups

### 5. Deploy

```bash
make apply
```

Confirm with `yes` when prompted.

### 6. Get API Gateway URL

After deployment:

```bash
terraform output api_gateway_url
```

Example output:

```
https://abc123xyz.execute-api.us-east-1.amazonaws.com/v1
```

## Testing

### Test Public Endpoint

```bash
curl -X POST https://your-api-gateway-url/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password123"
  }'
```

### Test Protected Endpoint

```bash
# Get token from login
TOKEN="your-jwt-token"

curl -X GET https://your-api-gateway-url/v1/users \
  -H "Authorization: Bearer $TOKEN"
```

## Updating

### Update Lambda Authorizer

```bash
make build-lambda
make apply
```

### Update Routes

Modify module files in `modules/` directory, then:

```bash
make plan
make apply
```

## Monitoring

### View API Gateway Logs

```bash
aws logs tail /aws/apigateway/oficina-tech-production --follow
```

### View Lambda Authorizer Logs

```bash
aws logs tail /aws/lambda/oficina-tech-jwt-authorizer-production --follow
```

### CloudWatch Metrics

Access CloudWatch console to view:

- Request count
- Latency
- 4XX/5XX errors
- Authorizer cache hits

## Troubleshooting

### 401 Unauthorized

- Check JWT secret matches backend
- Verify token is not expired
- Check Authorization header format: `Bearer <token>`

### 403 Forbidden

- Check user role in JWT token
- Verify RBAC configuration in backend

### 502 Bad Gateway

- Check ALB endpoint is accessible
- Verify backend service is running
- Check security groups allow traffic

### Lambda Authorizer Errors

Check logs:

```bash
aws logs tail /aws/lambda/oficina-tech-jwt-authorizer-production --follow
```

## Cleanup

To destroy all resources:

```bash
make destroy
```

Confirm with `yes` when prompted.

## Cost Estimation

Approximate monthly costs (us-east-1):

- API Gateway: $3.50 per million requests
- Lambda: $0.20 per million requests (first 1M free)
- CloudWatch Logs: $0.50 per GB ingested
- Data Transfer: $0.09 per GB

Example: 1M requests/month ≈ $5-10/month

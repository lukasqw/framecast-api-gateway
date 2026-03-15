# Integration Guide

## Integrating API Gateway with Existing Infrastructure

This guide explains how to integrate the API Gateway with your existing Oficina Tech infrastructure.

## Prerequisites

Before deploying the API Gateway, ensure you have:

1. **EKS Cluster** running with Oficina Tech backend
2. **Application Load Balancer (ALB)** configured and accessible
3. **Backend service** deployed and healthy
4. **JWT secret** configured in backend (environment variable `JWT_SECRET_KEY`)

## Integration Steps

### 1. Get ALB Endpoint

From your EKS/ALB infrastructure:

```bash
# If using Terraform outputs
cd ../infra
terraform output alb_endpoint

# Or using AWS CLI
aws elbv2 describe-load-balancers \
  --names oficina-tech-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text
```

Example output: `oficina-tech-alb-123456789.us-east-1.elb.amazonaws.com`

### 2. Configure API Gateway

Edit `api-gateway/terraform.tfvars`:

```hcl
alb_endpoint = "https://oficina-tech-alb-123456789.us-east-1.elb.amazonaws.com"
jwt_secret   = "same-secret-as-backend-JWT_SECRET_KEY"
```

**Important:** The `jwt_secret` MUST match the backend's `JWT_SECRET_KEY` environment variable.

### 3. Deploy API Gateway

```bash
cd api-gateway
make build-lambda
make init
make apply
```

### 4. Update Frontend Configuration

After deployment, update your frontend to use the API Gateway URL:

```javascript
// Before (direct to ALB)
const API_URL =
  "https://oficina-tech-alb-123456789.us-east-1.elb.amazonaws.com";

// After (through API Gateway)
const API_URL = "https://abc123xyz.execute-api.us-east-1.amazonaws.com/v1";
```

### 5. Update DNS (Optional)

Create a custom domain for your API:

```bash
# Create ACM certificate
aws acm request-certificate \
  --domain-name api.yourdomain.com \
  --validation-method DNS

# After validation, create custom domain in API Gateway
# Then create Route53 record pointing to API Gateway
```

## Security Configuration

### ALB Security Group

Update ALB security group to only accept traffic from API Gateway:

```hcl
# In your infra/sg.tf
resource "aws_security_group_rule" "alb_from_api_gateway" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # API Gateway uses AWS IP ranges
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from API Gateway"
}
```

### Backend Configuration

Ensure backend trusts API Gateway headers:

```go
// In your middleware, trust X-Forwarded-For from API Gateway
func (m *AuthMiddleware) Authenticate(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // API Gateway adds these headers
        userId := r.Header.Get("X-Apigateway-Context-UserId")
        userRole := r.Header.Get("X-Apigateway-Context-Role")

        // Your existing JWT validation...
    })
}
```

## Testing Integration

### 1. Health Check

```bash
# Test ALB directly (should work)
curl https://your-alb-endpoint.elb.amazonaws.com/health

# Test through API Gateway (should work)
curl https://your-api-gateway-url/v1/health
```

### 2. Authentication Flow

```bash
# Login through API Gateway
TOKEN=$(curl -s -X POST https://your-api-gateway-url/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}' \
  | jq -r '.token')

# Use token for protected endpoint
curl https://your-api-gateway-url/v1/users \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Run Test Suite

```bash
cd api-gateway
API_GATEWAY_URL=https://your-api-gateway-url/v1 \
  ./scripts/test-endpoints.sh
```

## Monitoring Integration

### CloudWatch Dashboard

Create a unified dashboard:

```bash
aws cloudwatch put-dashboard \
  --dashboard-name oficina-tech-full-stack \
  --dashboard-body file://dashboard.json
```

### Alarms

Set up alarms for:

- API Gateway 5XX errors
- Lambda authorizer errors
- ALB unhealthy targets
- High latency

## Rollback Procedure

If issues occur, rollback to direct ALB access:

1. Update frontend to use ALB URL directly
2. Keep API Gateway running (no cost when not used)
3. Investigate and fix issues
4. Re-enable API Gateway in frontend

## Cost Optimization

### Caching Strategy

Enable caching for read-heavy endpoints:

```hcl
# In modules/services/main.tf
resource "aws_api_gateway_method_settings" "services_get" {
  rest_api_id = var.api_gateway_id
  stage_name  = var.stage_name
  method_path = "services/GET"

  settings {
    caching_enabled = true
    cache_ttl_in_seconds = 300  # 5 minutes
  }
}
```

### Request Throttling

Adjust throttling based on usage:

```hcl
# In variables.tf
throttle_rate_limit  = 1000   # Reduce for lower costs
throttle_burst_limit = 500
```

## Troubleshooting

### Issue: 502 Bad Gateway

**Cause:** API Gateway cannot reach ALB

**Solution:**

1. Check ALB is running: `aws elbv2 describe-target-health`
2. Verify security groups allow traffic
3. Check ALB endpoint in terraform.tfvars

### Issue: 401 Unauthorized on all requests

**Cause:** JWT secret mismatch

**Solution:**

1. Verify backend JWT_SECRET_KEY
2. Update api-gateway terraform.tfvars
3. Redeploy: `make apply`

### Issue: High latency

**Cause:** Lambda cold starts

**Solution:**

1. Enable provisioned concurrency for Lambda
2. Increase authorizer cache TTL
3. Consider Lambda SnapStart (Java only)

## Migration Checklist

- [ ] ALB endpoint obtained
- [ ] JWT secret configured
- [ ] API Gateway deployed
- [ ] Lambda authorizer tested
- [ ] Frontend updated
- [ ] DNS updated (if using custom domain)
- [ ] Monitoring configured
- [ ] Alarms set up
- [ ] Team notified
- [ ] Documentation updated
- [ ] Rollback plan tested

## Support

For issues or questions:

1. Check CloudWatch logs
2. Review TROUBLESHOOTING.md
3. Contact DevOps team

# Lambda JWT Authorizer

This Lambda function validates JWT tokens for API Gateway requests.

## Build

```bash
cd lambda
npm install
npm run build
```

This creates `authorizer.zip` which is deployed by Terraform.

## Environment Variables

- `JWT_SECRET`: Secret key for JWT validation (must match backend)

## Token Format

The authorizer expects tokens in the Authorization header:

```
Authorization: Bearer <jwt-token>
```

## Token Claims

Expected JWT claims:

- `user_id` or `sub`: User ID
- `role`: User role (USER, MANAGER, ADMIN)
- `email`: User email (optional)

## Response

Returns IAM policy with context:

- `userId`: User ID from token
- `role`: User role
- `email`: User email

The backend receives these values in request headers.

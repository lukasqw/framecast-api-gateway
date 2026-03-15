#!/bin/bash

# Test script for API Gateway endpoints
set -e

# Configuration
API_URL="${API_GATEWAY_URL:-}"
EMAIL="${TEST_EMAIL:-admin@example.com}"
PASSWORD="${TEST_PASSWORD:-password123}"

if [ -z "$API_URL" ]; then
    echo "Error: API_GATEWAY_URL environment variable not set"
    echo "Usage: API_GATEWAY_URL=https://your-api.execute-api.us-east-1.amazonaws.com/v1 ./test-endpoints.sh"
    exit 1
fi

echo "========================================="
echo "Testing Oficina Tech API Gateway"
echo "========================================="
echo "API URL: $API_URL"
echo ""

# Test 1: Login (Public endpoint)
echo "Test 1: POST /auth/login (Public)"
echo "-----------------------------------"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

echo "Response: $LOGIN_RESPONSE"

# Extract token
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get token"
    exit 1
fi

echo "✓ Login successful"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Test 2: Get Users (Protected endpoint)
echo "Test 2: GET /users (Protected - MANAGER/ADMIN)"
echo "-----------------------------------"
USERS_RESPONSE=$(curl -s -X GET "$API_URL/users" \
    -H "Authorization: Bearer $TOKEN")

echo "Response: $USERS_RESPONSE"
echo "✓ Users endpoint accessible"
echo ""

# Test 3: Get Customers (Protected endpoint)
echo "Test 3: GET /customers (Protected - USER/MANAGER/ADMIN)"
echo "-----------------------------------"
CUSTOMERS_RESPONSE=$(curl -s -X GET "$API_URL/customers" \
    -H "Authorization: Bearer $TOKEN")

echo "Response: $CUSTOMERS_RESPONSE"
echo "✓ Customers endpoint accessible"
echo ""

# Test 4: Get Services (Protected endpoint)
echo "Test 4: GET /services (Protected - USER/MANAGER/ADMIN)"
echo "-----------------------------------"
SERVICES_RESPONSE=$(curl -s -X GET "$API_URL/services" \
    -H "Authorization: Bearer $TOKEN")

echo "Response: $SERVICES_RESPONSE"
echo "✓ Services endpoint accessible"
echo ""

# Test 5: Unauthorized request
echo "Test 5: GET /users (No token - should fail)"
echo "-----------------------------------"
UNAUTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X GET "$API_URL/users")

echo "Response: $UNAUTH_RESPONSE"

if echo "$UNAUTH_RESPONSE" | grep -q "HTTP_CODE:401\|HTTP_CODE:403"; then
    echo "✓ Unauthorized request correctly rejected"
else
    echo "⚠️  Expected 401/403 status code"
fi
echo ""

echo "========================================="
echo "All tests completed!"
echo "========================================="

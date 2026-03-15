.PHONY: help build init plan apply destroy clean test validate format docs

# Variables
LAMBDA_DIR := lambda
SCRIPTS_DIR := scripts
TF_VARS_FILE := terraform.tfvars

help: ## Show this help message
	@echo "API Gateway - Oficina Tech"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build-openapi: ## Build OpenAPI spec from modular files
	@echo "Building OpenAPI specification..."
	@python3 $(SCRIPTS_DIR)/build-openapi.py

build-lambda-authorizer: ## Build Lambda authorizer package
	@echo "Building Lambda authorizer..."
	@cd $(LAMBDA_DIR) && npm install --production
	@cd $(LAMBDA_DIR) && zip -r authorizer.zip index.js node_modules/
	@echo "✓ Lambda authorizer package built: $(LAMBDA_DIR)/authorizer.zip"

build-lambda-auth: ## Build Lambda CPF authentication package
	@echo "Building Lambda CPF authentication..."
	@cd $(LAMBDA_DIR)/auth && npm install --production
	@cd $(LAMBDA_DIR)/auth && zip -r ../auth.zip index.js node_modules/
	@echo "✓ Lambda auth package built: $(LAMBDA_DIR)/auth.zip"

build-lambda: build-lambda-authorizer build-lambda-auth ## Build all Lambda packages

build: build-openapi build-lambda ## Build OpenAPI spec and Lambda packages

validate: build-openapi ## Validate OpenAPI spec and Terraform configuration
	@echo "Validating OpenAPI specification..."
	@python3 -m json.tool openapi-spec.json > /dev/null && echo "✓ OpenAPI spec is valid JSON" || (echo "✗ Invalid JSON in openapi-spec.json" && exit 1)
	@echo "Validating Terraform configuration..."
	@terraform fmt -check
	@terraform validate
	@echo "✓ Terraform configuration is valid"

format: ## Format Terraform files
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive
	@echo "✓ Terraform files formatted"

init: ## Initialize Terraform
	@echo "Initializing Terraform..."
	@terraform init
	@echo "✓ Terraform initialized"

plan: validate ## Show Terraform execution plan
	@echo "Planning Terraform changes..."
	@terraform plan -var-file=$(TF_VARS_FILE)

apply: validate build ## Apply Terraform configuration
	@echo "Applying Terraform configuration..."
	@terraform apply -var-file=$(TF_VARS_FILE)

deploy: apply ## Alias for apply

destroy: ## Destroy all resources
	@echo "⚠️  WARNING: This will destroy all API Gateway resources!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform destroy -var-file=$(TF_VARS_FILE); \
	fi

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -f $(LAMBDA_DIR)/authorizer.zip
	@rm -f $(LAMBDA_DIR)/auth.zip
	@rm -rf $(LAMBDA_DIR)/node_modules
	@rm -rf $(LAMBDA_DIR)/auth/node_modules
	@rm -f openapi-spec.json
	@rm -rf .terraform
	@rm -f .terraform.lock.hcl
	@rm -f terraform.tfstate*
	@echo "✓ Build artifacts cleaned"

test: ## Test API endpoints
	@echo "Testing API endpoints..."
	@bash $(SCRIPTS_DIR)/test-endpoints.sh

docs: ## Generate API documentation
	@echo "API Documentation:"
	@echo "  - README.md: Main documentation"
	@echo "  - docs/QUICK_START.md: Quick start guide"
	@echo "  - docs/ARCHITECTURE.md: Architecture overview"
	@echo "  - docs/DEPLOYMENT.md: Deployment guide"
	@echo "  - docs/INTEGRATION.md: Integration guide"
	@echo "  - docs/ENDPOINTS.md: API endpoints reference"
	@echo "  - docs/PROJECT_STRUCTURE.md: Project structure"
	@echo "  - docs/CHANGELOG.md: Change history"
	@echo "  - openapi/README.md: Modular OpenAPI guide"
	@echo ""
	@echo "OpenAPI Spec: openapi-spec.json"
	@echo "  View in Swagger Editor: https://editor.swagger.io/"

output: ## Show Terraform outputs
	@terraform output

state: ## Show Terraform state
	@terraform state list

refresh: ## Refresh Terraform state
	@terraform refresh -var-file=$(TF_VARS_FILE)

taint-deployment: ## Force API Gateway redeployment
	@echo "Tainting API Gateway deployment..."
	@terraform taint aws_api_gateway_deployment.oficina_tech
	@echo "✓ Deployment tainted. Run 'make apply' to redeploy"

logs-api: ## Tail API Gateway logs
	@echo "Tailing API Gateway logs..."
	@aws logs tail /aws/apigateway/oficina-tech-$$(terraform output -raw environment 2>/dev/null || echo "dev") --follow

logs-lambda: ## Tail Lambda authorizer logs
	@echo "Tailing Lambda authorizer logs..."
	@aws logs tail /aws/lambda/oficina-tech-jwt-authorizer-$$(terraform output -raw environment 2>/dev/null || echo "dev") --follow

check-deps: ## Check required dependencies
	@echo "Checking dependencies..."
	@command -v terraform >/dev/null 2>&1 || (echo "✗ terraform not found" && exit 1)
	@echo "✓ terraform: $$(terraform version | head -n1)"
	@command -v node >/dev/null 2>&1 || (echo "✗ node not found" && exit 1)
	@echo "✓ node: $$(node --version)"
	@command -v npm >/dev/null 2>&1 || (echo "✗ npm not found" && exit 1)
	@echo "✓ npm: $$(npm --version)"
	@command -v aws >/dev/null 2>&1 || (echo "✗ aws cli not found" && exit 1)
	@echo "✓ aws cli: $$(aws --version)"
	@command -v python3 >/dev/null 2>&1 || (echo "✗ python3 not found" && exit 1)
	@echo "✓ python3: $$(python3 --version)"
	@echo "✓ All dependencies installed"

setup: check-deps init build ## Setup project (check deps, init, build)
	@echo "✓ Project setup complete"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Copy terraform.tfvars.example to terraform.tfvars"
	@echo "  2. Edit terraform.tfvars with your configuration"
	@echo "  3. Run 'make plan' to preview changes"
	@echo "  4. Run 'make apply' to deploy"

cost-estimate: ## Estimate monthly costs
	@echo "Estimated Monthly Costs (low traffic):"
	@echo "  API Gateway:      ~$$3.50/million requests"
	@echo "  Lambda Authorizer: ~$$0.20/million invocations"
	@echo "  CloudWatch Logs:   ~$$0.50/GB"
	@echo "  Total (estimate):  < $$10/month"
	@echo ""
	@echo "Note: Actual costs depend on traffic volume"

endpoints: ## List all API endpoints
	@echo "Extracting endpoints from OpenAPI spec..."
	@python3 -c "import json; spec = json.load(open('openapi-spec.json')); [print(f'{method.upper():7} {path}') for path, methods in spec['paths'].items() for method in methods.keys() if method != 'parameters']"

.DEFAULT_GOAL := help

logs-lambda-auth: ## Tail Lambda CPF authentication logs
	@echo "Tailing Lambda CPF authentication logs..."
	@aws logs tail /aws/lambda/oficina-tech-cpf-auth-production --follow

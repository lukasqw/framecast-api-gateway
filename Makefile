# Makefile for Oficina Tech API Gateway
.PHONY: help build init plan apply destroy clean test validate format lint check-deps
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show available commands
	@echo "$(BLUE)Oficina Tech API Gateway - Available Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-deps: ## Check required dependencies
	@echo "$(BLUE)Checking dependencies...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)Error: terraform not installed$(NC)"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "$(RED)Error: python3 not installed$(NC)"; exit 1; }
	@command -v node >/dev/null 2>&1 || { echo "$(RED)Error: node not installed$(NC)"; exit 1; }
	@command -v npm >/dev/null 2>&1 || { echo "$(RED)Error: npm not installed$(NC)"; exit 1; }
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

build: check-deps ## Build Lambda packages and OpenAPI spec
	@echo "$(BLUE)Building Lambda packages...$(NC)"
	@cd lambda/auth && npm install --production && cd ../.. && cd lambda/auth && zip -r ../auth.zip index.js utils.js node_modules/ && cd ../..
	@echo "$(GREEN)✓ Lambda packages built$(NC)"
	@echo "$(BLUE)Building OpenAPI spec...$(NC)"
	@python3 scripts/build-openapi-consolidated.py
	@echo "$(GREEN)✓ OpenAPI spec built$(NC)"

init: check-deps ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	@terraform init
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform...$(NC)"
	@terraform validate
	@echo "$(GREEN)✓ Terraform configuration valid$(NC)"

format: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive
	@echo "$(GREEN)✓ Files formatted$(NC)"

lint: validate format ## Lint and validate all files
	@echo "$(GREEN)✓ Linting complete$(NC)"

plan: validate ## Plan Terraform changes
	@echo "$(BLUE)Planning Terraform changes...$(NC)"
	@terraform plan -out=tfplan
	@echo "$(GREEN)✓ Plan created$(NC)"

apply: ## Apply Terraform changes
	@echo "$(BLUE)Applying Terraform changes...$(NC)"
	@terraform apply tfplan
	@echo "$(GREEN)✓ Changes applied$(NC)"

apply-auto: build plan ## Build, plan and apply automatically
	@echo "$(BLUE)Auto-applying changes...$(NC)"
	@terraform apply -auto-approve
	@echo "$(GREEN)✓ Changes applied$(NC)"

destroy: ## Destroy resources
	@echo "$(RED)Destroying resources...$(NC)"
	@terraform destroy
	@echo "$(GREEN)✓ Resources destroyed$(NC)"

clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -f lambda/*.zip
	@rm -f tfplan*
	@rm -f openapi-spec.json
	@rm -rf lambda/auth/node_modules
	@echo "$(GREEN)✓ Artifacts cleaned$(NC)"

test: ## Test endpoints
	@echo "$(BLUE)Testing endpoints...$(NC)"
	@bash scripts/test-auth.sh || echo "$(YELLOW)Warning: test-auth.sh not found$(NC)"
	@bash scripts/test-endpoints.sh || echo "$(YELLOW)Warning: test-endpoints.sh not found$(NC)"

outputs: ## Show Terraform outputs
	@terraform output

state-list: ## List Terraform state resources
	@terraform state list

refresh: ## Refresh Terraform state
	@terraform refresh

show: ## Show Terraform state
	@terraform show

fix-state: ## Fix Terraform state issues
	@echo "$(YELLOW)Fixing Terraform state...$(NC)"
	@rm -f terraform.tfstate terraform.tfstate.backup tfplan
	@rm -rf .terraform
	@echo "$(GREEN)✓ Local state removed$(NC)"
	@terraform init -reconfigure
	@echo "$(GREEN)✓ Reinitialized with S3 backend$(NC)"
	@terraform state list || echo "$(YELLOW)State is empty (OK for first deploy)$(NC)"

upgrade: ## Upgrade Terraform providers
	@terraform init -upgrade

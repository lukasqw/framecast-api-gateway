# Simplified Makefile for AWS Academy
.PHONY: help build init plan apply destroy clean test
.DEFAULT_GOAL := help

help: ## Show available commands
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build Lambda packages and OpenAPI spec
	@echo "Building Lambda packages..."
	@cd lambda && npm install --production && zip -r authorizer.zip index.js node_modules/
	@cd lambda/auth && npm install --production && zip -r ../auth.zip index.js utils.js node_modules/
	@echo "Building OpenAPI spec..."
	@python3 scripts/build-openapi-consolidated.py

init: ## Initialize Terraform
	@terraform init

plan: ## Plan Terraform changes
	@terraform plan

apply: ## Apply Terraform changes
	@terraform apply

destroy: ## Destroy resources
	@terraform destroy

clean: ## Clean build artifacts
	@rm -f lambda/*.zip
	@rm -f tfplan*
	@rm -f openapi-spec.json

test: ## Test endpoints
	@./scripts/test-auth.sh
	@./scripts/test-endpoints.sh

validate: ## Validate Terraform
	@terraform validate

format: ## Format Terraform files
	@terraform fmt -recursive
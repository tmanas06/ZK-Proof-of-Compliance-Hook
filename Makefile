.PHONY: help install build test test-verbose clean lint format deploy-local

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	@echo "Installing dependencies..."
	forge install
	npm install
	cd frontend && npm install

build: ## Compile contracts
	@echo "Building contracts..."
	forge build

test: ## Run tests
	@echo "Running tests..."
	forge test

test-verbose: ## Run tests with verbose output
	@echo "Running tests with verbose output..."
	forge test -vvv

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	forge coverage

clean: ## Clean build artifacts
	@echo "Cleaning..."
	forge clean
	rm -rf out cache_forge

lint: ## Lint contracts
	@echo "Linting contracts..."
	forge fmt --check
	solhint 'src/**/*.sol'

format: ## Format contracts
	@echo "Formatting contracts..."
	forge fmt

deploy-local: ## Deploy to local network
	@echo "Deploying to local network..."
	forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast

frontend-dev: ## Start frontend development server
	@echo "Starting frontend..."
	cd frontend && npm run dev

frontend-build: ## Build frontend for production
	@echo "Building frontend..."
	cd frontend && npm run build


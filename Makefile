.PHONY: help install-prereqs dev teardown restart build logs logs-api logs-frontend logs-postgres logs-redis status seed-db test shell-api db-shell clean validate

# Load config and export variables
-include .config.env
export

NAMESPACE := wander-dev
WORKSPACE_PATH := $(shell pwd)

# Set default ports if not in .env
FRONTEND_PORT ?= 3000
API_PORT ?= 4000
POSTGRES_PORT ?= 5432
REDIS_PORT ?= 6379

# Detect environment and set Dockerfile suffix
# Default to development if NODE_ENV is not set
NODE_ENV ?= development
# Use .dev suffix for development, empty for production
DOCKERFILE_SUFFIX := $(if $(filter production,$(NODE_ENV)),,.dev)

help: ## Display this help message
	@echo "Wander Developer Environment - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-15s\033[0m %s\n", $$1, $$2}'

install-prereqs: ## Install required prerequisites (detects OS automatically)
	@./scripts/install-prerequisites.sh

dev: install-prereqs validate ## Start the entire development environment
	@echo ""
	@echo "🚀 Starting Wander Development Environment"
	@echo "════════════════════════════════════════"
	@echo ""
	@echo "Step 1/8: Checking system requirements..."
	./scripts/preflight-check.sh
	@echo ""
	@echo "Step 2/8: Loading configuration..."
	@node scripts/load-config.js >/dev/null 2>&1 || (echo "❌ Configuration error. Please check your setup." && exit 1)
	@echo "  ✓ Configuration loaded"
	@echo ""
	@echo "Step 3/8: Preparing deployment files..."
	mkdir -p .pids infra/generated
	@export WORKSPACE_PATH=$(WORKSPACE_PATH) && ./scripts/prepare-manifests.sh
	@echo ""
	@echo "Step 4/8: Building application images..."
	@echo "  Building API server..."
	@(if minikube status 2>/dev/null | grep -q Running; then eval $$(minikube docker-env); fi; docker build --quiet -t wander-api:latest -f services/api/Dockerfile$(DOCKERFILE_SUFFIX) . >/dev/null 2>&1 && echo "  ✓ API image built" || (echo "  ❌ Failed to build API image" && exit 1))
	@echo "  Building frontend..."
	@(if minikube status 2>/dev/null | grep -q Running; then eval $$(minikube docker-env); fi; docker build --quiet -t wander-frontend:latest -f services/frontend/Dockerfile$(DOCKERFILE_SUFFIX) . >/dev/null 2>&1 && echo "  ✓ Frontend image built" || (echo "  ❌ Failed to build frontend image" && exit 1))
	@echo ""
	@echo "Step 5/8: Deploying to Kubernetes..."
	@kubectl apply -f infra/generated/namespace.yaml >/dev/null 2>&1 && echo "  ✓ Namespace created"
	@kubectl apply -f infra/generated/configmap.yaml >/dev/null 2>&1 && echo "  ✓ Configuration applied"
	@kubectl apply -f infra/generated/seed-configmap.yaml >/dev/null 2>&1 && echo "  ✓ Database seed prepared"
	@kubectl apply -f infra/generated/postgres.yaml >/dev/null 2>&1 && echo "  ✓ Database deployed"
	@kubectl apply -f infra/generated/redis.yaml >/dev/null 2>&1 && echo "  ✓ Cache deployed"
	@kubectl apply -f infra/generated/api.yaml >/dev/null 2>&1 && echo "  ✓ API server deployed"
	@kubectl apply -f infra/generated/frontend.yaml >/dev/null 2>&1 && echo "  ✓ Frontend deployed"
	@echo ""
	@echo "Step 6/8: Waiting for services to be healthy..."
	./scripts/wait-for-services.sh
	@echo ""
	@echo "Step 7/8: Setting up network connections..."
	@kubectl port-forward -n $(NAMESPACE) svc/frontend $(FRONTEND_PORT):3000 >/dev/null 2>&1 & echo $$! > .pids/frontend.pid && echo "  ✓ Frontend: http://localhost:$(FRONTEND_PORT)"
	@kubectl port-forward -n $(NAMESPACE) svc/api $(API_PORT):4000 >/dev/null 2>&1 & echo $$! > .pids/api.pid && echo "  ✓ API: http://localhost:$(API_PORT)"
	@kubectl port-forward -n $(NAMESPACE) svc/postgres $(POSTGRES_PORT):5432 >/dev/null 2>&1 & echo $$! > .pids/postgres.pid && echo "  ✓ Database: localhost:$(POSTGRES_PORT)"
	@kubectl port-forward -n $(NAMESPACE) svc/redis $(REDIS_PORT):6379 >/dev/null 2>&1 & echo $$! > .pids/redis.pid && echo "  ✓ Cache: localhost:$(REDIS_PORT)"
	@sleep 2
	@echo ""
	@echo "════════════════════════════════════════"
	@echo "✅ Environment is ready!"
	@echo "════════════════════════════════════════"
	@echo ""
	@echo "🌐 Access your application:"
	@echo "   • Frontend:   http://localhost:$(FRONTEND_PORT)"
	@echo "   • API Health: http://localhost:$(API_PORT)/health"
	@echo ""
	@echo "💡 Useful commands:"
	@echo "   • make status     - Check service status"
	@echo "   • make logs       - View all logs"
	@echo "   • make teardown   - Stop everything"
	@echo ""

teardown: ## Stop and clean up the entire environment
	@echo "🧹 Cleaning up environment..."
	@if [ -d .pids ]; then \
		for pid_file in .pids/*.pid; do \
			[ -f "$$pid_file" ] && kill $$(cat "$$pid_file") 2>/dev/null || true; \
		done; \
		rm -rf .pids; \
	fi
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	@rm -rf infra/generated
	@echo "✅ Environment cleaned up"

restart: teardown dev ## Restart the environment (teardown + dev)

build: ## Build Docker images only
	@echo "🔨 Building Docker images (NODE_ENV=$(NODE_ENV), using Dockerfile$(DOCKERFILE_SUFFIX))..."
	@(if minikube status 2>/dev/null | grep -q Running; then eval $$(minikube docker-env); fi; docker build -t wander-api:latest -f services/api/Dockerfile$(DOCKERFILE_SUFFIX) .)
	@(if minikube status 2>/dev/null | grep -q Running; then eval $$(minikube docker-env); fi; docker build -t wander-frontend:latest -f services/frontend/Dockerfile$(DOCKERFILE_SUFFIX) .)
	@echo "✅ Images built successfully"

logs: ## Stream logs from all pods
	@kubectl logs -f -n $(NAMESPACE) -l app=api & \
	kubectl logs -f -n $(NAMESPACE) -l app=frontend & \
	kubectl logs -f -n $(NAMESPACE) -l app=postgres & \
	kubectl logs -f -n $(NAMESPACE) -l app=redis & \
	wait

logs-api: ## Stream logs from API pod only
	@kubectl logs -f -n $(NAMESPACE) -l app=api

logs-frontend: ## Stream logs from frontend pod only
	@kubectl logs -f -n $(NAMESPACE) -l app=frontend

logs-postgres: ## Stream logs from postgres pod only
	@kubectl logs -f -n $(NAMESPACE) -l app=postgres

logs-redis: ## Stream logs from redis pod only
	@kubectl logs -f -n $(NAMESPACE) -l app=redis

status: ## Check status of all pods
	@kubectl get pods -n $(NAMESPACE)

seed-db: ## Manually reseed the database
	@kubectl exec -n $(NAMESPACE) deployment/postgres -- psql -U postgres -d wander_dev -f /docker-entrypoint-initdb.d/seed.sql

test: ## Run integration tests
	@npm test

shell-api: ## Open shell in API pod
	@kubectl exec -it -n $(NAMESPACE) deployment/api -- sh

db-shell: ## Open psql shell in database pod
	@kubectl exec -it -n $(NAMESPACE) deployment/postgres -- psql -U postgres -d wander_dev

clean: ## Remove all Docker images
	@docker rmi wander-api:latest wander-frontend:latest 2>/dev/null || true
	@echo "✅ Docker images removed"

validate: ## Run system validation checks
	@./scripts/validate-system.sh


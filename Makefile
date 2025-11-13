.PHONY: help install-prereqs dev teardown restart build logs logs-api logs-frontend logs-postgres logs-redis status seed-db test shell-api db-shell clean validate

# Include .env file if it exists
-include .env
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
	@echo "========================================"
	@echo "🚀 STARTING WANDER DEV ENVIRONMENT"
	@echo "========================================"
	@echo ""
	@echo "📋 Step 1: Running preflight checks..."
	@echo "----------------------------------------"
	./scripts/preflight-check.sh
	@echo ""
	@echo "📋 Step 2: Checking .env file..."
	@echo "----------------------------------------"
	[ -f .env ] && echo "✓ .env file exists" || (echo "⚠ Creating .env from .env.example" && cp .env.example .env)
	@echo ""
	@echo "📋 Step 3: Creating required directories..."
	@echo "----------------------------------------"
	mkdir -p .pids infra/generated
	@echo "✓ Created .pids directory"
	@echo "✓ Created infra/generated directory"
	@echo ""
	@echo "📋 Step 4: Preparing Kubernetes manifests..."
	@echo "----------------------------------------"
	@echo "WORKSPACE_PATH=$(WORKSPACE_PATH)"
	export WORKSPACE_PATH=$(WORKSPACE_PATH) && ./scripts/prepare-manifests.sh
	@echo ""
	@echo "🔨 Step 5: Building Docker images..."
	@echo "========================================"
	@echo ""
	@echo "Building wander-api:latest (using Dockerfile$(DOCKERFILE_SUFFIX))..."
	@echo "----------------------------------------"
	@(if minikube status 2>/dev/null | grep -q Running; then eval $$(minikube docker-env); fi; docker build --progress=plain -t wander-api:latest -f services/api/Dockerfile$(DOCKERFILE_SUFFIX) .)
	@echo ""
	@echo "Building wander-frontend:latest (using Dockerfile$(DOCKERFILE_SUFFIX))..."
	@echo "----------------------------------------"
	@(if minikube status 2>/dev/null | grep -q Running; then eval $$(minikube docker-env); fi; docker build --progress=plain -t wander-frontend:latest -f services/frontend/Dockerfile$(DOCKERFILE_SUFFIX) .)
	@echo ""
	@echo "🎯 Step 6: Applying Kubernetes manifests..."
	@echo "========================================"
	@echo ""
	@echo "Applying namespace.yaml..."
	kubectl apply -f infra/generated/namespace.yaml -v=5
	@echo ""
	@echo "Applying configmap.yaml..."
	kubectl apply -f infra/generated/configmap.yaml -v=5
	@echo ""
	@echo "Applying seed-configmap.yaml..."
	kubectl apply -f infra/generated/seed-configmap.yaml -v=5
	@echo "Verifying ConfigMap was created..."
	@kubectl get configmap wander-seed-script -n $(NAMESPACE) || (echo "❌ ERROR: ConfigMap wander-seed-script not found!" && exit 1)
	@echo "✓ ConfigMap verified"
	@echo ""
	@echo "Applying postgres.yaml..."
	kubectl apply -f infra/generated/postgres.yaml -v=5
	@echo ""
	@echo "Applying redis.yaml..."
	kubectl apply -f infra/generated/redis.yaml -v=5
	@echo ""
	@echo "Applying api.yaml..."
	kubectl apply -f infra/generated/api.yaml -v=5
	@echo ""
	@echo "Applying frontend.yaml..."
	kubectl apply -f infra/generated/frontend.yaml -v=5
	@echo ""
	@echo "⏳ Step 7: Waiting for services to be ready..."
	@echo "========================================"
	./scripts/wait-for-services.sh
	@echo ""
	@echo "🔌 Step 8: Setting up port forwards..."
	@echo "========================================"
	@echo "Port forwarding frontend ($(FRONTEND_PORT):3000)..."
	kubectl port-forward -n $(NAMESPACE) svc/frontend $(FRONTEND_PORT):3000 -v=5 & echo $$! > .pids/frontend.pid
	@echo "✓ Frontend port-forward PID: $$(cat .pids/frontend.pid)"
	@echo ""
	@echo "Port forwarding API ($(API_PORT):4000)..."
	kubectl port-forward -n $(NAMESPACE) svc/api $(API_PORT):4000 -v=5 & echo $$! > .pids/api.pid
	@echo "✓ API port-forward PID: $$(cat .pids/api.pid)"
	@echo ""
	@echo "Port forwarding Postgres ($(POSTGRES_PORT):5432)..."
	kubectl port-forward -n $(NAMESPACE) svc/postgres $(POSTGRES_PORT):5432 -v=5 & echo $$! > .pids/postgres.pid
	@echo "✓ Postgres port-forward PID: $$(cat .pids/postgres.pid)"
	@echo ""
	@echo "Port forwarding Redis ($(REDIS_PORT):6379)..."
	kubectl port-forward -n $(NAMESPACE) svc/redis $(REDIS_PORT):6379 -v=5 & echo $$! > .pids/redis.pid
	@echo "✓ Redis port-forward PID: $$(cat .pids/redis.pid)"
	@echo ""
	@echo "Waiting for port-forwards to establish..."
	sleep 2
	@echo ""
	@echo "========================================"
	@echo "✅ ENVIRONMENT IS READY!"
	@echo "========================================"
	@echo ""
	@echo "📝 Access your environment:"
	@echo "   Frontend:   http://localhost:$(FRONTEND_PORT)"
	@echo "   API:        http://localhost:$(API_PORT)"
	@echo "   API Health: http://localhost:$(API_PORT)/health"
	@echo "   Postgres:   localhost:$(POSTGRES_PORT)"
	@echo "   Redis:      localhost:$(REDIS_PORT)"
	@echo ""
	@echo "🔍 Monitor logs with:"
	@echo "   make logs          # All services"
	@echo "   make logs-api      # API only"
	@echo "   make logs-frontend # Frontend only"
	@echo ""
	@echo "========================================"

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


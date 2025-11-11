.PHONY: help install-prereqs dev teardown restart build logs logs-api logs-frontend logs-postgres logs-redis status seed-db test shell-api db-shell clean validate

# Include .env file if it exists
-include .env
export

NAMESPACE := wander-dev
WORKSPACE_PATH := $(shell pwd)

help: ## Display this help message
	@echo "Wander Developer Environment - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-15s\033[0m %s\n", $$1, $$2}'

install-prereqs: ## Install required prerequisites (detects OS automatically)
	@./scripts/install-prerequisites.sh

dev: install-prereqs validate ## Start the entire development environment
	@./scripts/preflight-check.sh
	@[ -f .env ] || cp .env.example .env
	@mkdir -p .pids infra/generated
	@export WORKSPACE_PATH=$(WORKSPACE_PATH) && ./scripts/prepare-manifests.sh
	@echo "🔨 Building Docker images..."
	@docker build -t wander-api:latest -f services/api/Dockerfile .
	@docker build -t wander-frontend:latest -f services/frontend/Dockerfile .
	@echo "🎯 Applying Kubernetes manifests..."
	@kubectl apply -f infra/generated/namespace.yaml
	@kubectl apply -f infra/generated/configmap.yaml
	@kubectl apply -f infra/generated/postgres.yaml
	@kubectl apply -f infra/generated/redis.yaml
	@kubectl apply -f infra/generated/api.yaml
	@kubectl apply -f infra/generated/frontend.yaml
	@./scripts/wait-for-services.sh
	@echo "🔌 Setting up port forwards..."
	@kubectl port-forward -n $(NAMESPACE) svc/frontend 3000:3000 > /dev/null 2>&1 & echo $$! > .pids/frontend.pid
	@kubectl port-forward -n $(NAMESPACE) svc/api 4000:4000 > /dev/null 2>&1 & echo $$! > .pids/api.pid
	@kubectl port-forward -n $(NAMESPACE) svc/postgres 5432:5432 > /dev/null 2>&1 & echo $$! > .pids/postgres.pid
	@kubectl port-forward -n $(NAMESPACE) svc/redis 6379:6379 > /dev/null 2>&1 & echo $$! > .pids/redis.pid
	@sleep 2
	@echo "✅ Environment is ready!"
	@echo "📝 Access your environment:"
	@echo "   Frontend:  http://localhost:3000"
	@echo "   API:       http://localhost:4000"
	@echo "   API Health: http://localhost:4000/health"

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
	@echo "🔨 Building Docker images..."
	@docker build -t wander-api:latest -f services/api/Dockerfile .
	@docker build -t wander-frontend:latest -f services/frontend/Dockerfile .
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


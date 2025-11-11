# PR #7: Makefile & Automation Scripts

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

**Goal:** Create the complete Makefile and all helper scripts for deployment, monitoring, and management.

## Files to Create

**Makefile:**
```makefile
.PHONY: help dev teardown restart build logs logs-api logs-frontend logs-postgres logs-redis status seed-db test shell-api db-shell clean

# Include .env file if it exists
-include .env
export

NAMESPACE := wander-dev
WORKSPACE_PATH := $(shell pwd)

help: ## Display this help message
	@echo "Wander Developer Environment - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-15s\033[0m %s\n", $$1, $$2}'

dev: ## Start the entire development environment
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
```

**scripts/preflight-check.sh:**
```bash
#!/bin/bash
set -e

echo "🚀 Starting Zero-to-Running Developer Environment..."

# Detect OS
OS=$(uname -s)
echo "📋 Platform: $OS"

# Check Docker
echo -n "Checking Docker... "
if ! command -v docker &> /dev/null || ! docker ps &> /dev/null; then
  echo "❌ Docker is not running. Start Docker Desktop and try again."
  exit 1
fi
echo "✅"

# Check kubectl
echo -n "Checking kubectl... "
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Install kubectl and try again."
  exit 1
fi
if ! kubectl cluster-info &> /dev/null; then
  echo "❌ Kubernetes not configured. Enable in Docker Desktop or install Minikube."
  exit 1
fi
echo "✅"

# Check envsubst
echo -n "Checking envsubst... "
if ! command -v envsubst &> /dev/null; then
  echo "❌ envsubst not found. Install gettext package."
  exit 1
fi
echo "✅"

# Check make
echo -n "Checking make... "
if ! command -v make &> /dev/null; then
  echo "❌ make not found. Install make and try again."
  exit 1
fi
echo "✅"

# Check disk space
DISK_AVAIL=$(df -k . | awk 'NR==2 {print $4}')
if [ "$DISK_AVAIL" -lt 10485760 ]; then
  echo "⚠️  Warning: Less than 10GB disk space available"
fi

# Check memory (macOS vs Linux)
if [ "$OS" = "Darwin" ]; then
  MEM_TOTAL=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024}')
else
  MEM_TOTAL=$(free -g | awk 'NR==2 {print $2}')
fi
if [ "${MEM_TOTAL%.*}" -lt 4 ]; then
  echo "⚠️  Warning: Less than 4GB RAM available"
fi

# Check ports
for PORT in 3000 4000 5432 6379; do
  if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -an | grep -q ":$PORT.*LISTEN" 2>/dev/null; then
    echo "❌ Port $PORT is already in use. Stop the process or change ${PORT}_PORT in .env"
    exit 1
  fi
done

echo "✅ All preflight checks passed"
exit 0
```

**scripts/wait-for-services.sh:**
```bash
#!/bin/bash
set -e

NAMESPACE="wander-dev"
MAX_ATTEMPTS=60
INTERVAL=5

echo "⏳ Waiting for all services to be healthy..."

wait_for_pod() {
  local SERVICE=$1
  local ATTEMPTS=0
  
  echo "  ⏳ $SERVICE: starting..."
  
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    if kubectl get pods -n $NAMESPACE -l app=$SERVICE 2>/dev/null | grep -q "Running"; then
      if kubectl exec -n $NAMESPACE deployment/$SERVICE -- curl -f http://localhost:${2:-4000}/health/ready &>/dev/null 2>&1; then
        echo "  ✅ $SERVICE: ready"
        return 0
      fi
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    sleep $INTERVAL
  done
  
  echo "  ❌ $SERVICE: failed to start"
  kubectl logs -n $NAMESPACE -l app=$SERVICE --tail=50
  return 1
}

# Wait for postgres
wait_for_pod postgres 5432 &
PG_PID=$!

# Wait for redis
wait_for_pod redis 6379 &
REDIS_PID=$!

# Wait for database services first
wait $PG_PID || exit 1
wait $REDIS_PID || exit 1

# Now wait for application services
wait_for_pod api 4000 &
API_PID=$!

wait_for_pod frontend 3000 &
FRONTEND_PID=$!

# Wait for all
wait $API_PID || exit 1
wait $FRONTEND_PID || exit 1

echo "✅ All services are healthy!"
exit 0
```

**scripts/handle-error.sh:**
- Common error handling utilities
- Functions for displaying formatted error messages
- Suggestions based on error type

**scripts/validate-seed.sh:**
- Query database for row counts
- Verify 5 users, 2 teams, 2 projects, 6 tasks, 10 activities
- Log success or warning

**scripts/prepare-manifests.sh:**
```bash
#!/bin/bash
set -e

NODE_ENV=${NODE_ENV:-development}
WORKSPACE_PATH=${WORKSPACE_PATH:-$(pwd)}

echo "🔨 Preparing Kubernetes manifests for $NODE_ENV environment..."

# Create generated directory
mkdir -p infra/generated

# Export variables for envsubst
export NODE_ENV
export WORKSPACE_PATH

# Generate conditional blocks based on environment
if [ "$NODE_ENV" = "development" ]; then
  # Development: include volume mounts and dev commands
  export DEV_API_VOLUME=$(cat <<EOF
        volumeMounts:
        - name: api-src
          mountPath: /app/src
      volumes:
      - name: api-src
        hostPath:
          path: ${WORKSPACE_PATH}/services/api/src
          type: Directory
EOF
)
  export DEV_FRONTEND_VOLUME=$(cat <<EOF
        volumeMounts:
        - name: frontend-src
          mountPath: /app/src
      volumes:
      - name: frontend-src
        hostPath:
          path: ${WORKSPACE_PATH}/services/frontend/src
          type: Directory
EOF
)
  export API_COMMAND='["npm", "run", "dev"]'
  export FRONTEND_COMMAND='["npm", "run", "dev"]'
else
  # Production: no volumes, use production commands
  export DEV_API_VOLUME=""
  export DEV_FRONTEND_VOLUME=""
  export API_COMMAND='["npm", "start"]'
  export FRONTEND_COMMAND='["serve", "-s", "dist", "-l", "3000", "--no-clipboard"]'
fi

# Process all YAML files
for file in infra/k8s/*.yaml; do
  filename=$(basename "$file")
  envsubst < "$file" > "infra/generated/$filename"
  echo "  ✅ Generated infra/generated/$filename"
done

echo "✅ Manifests prepared successfully"
```

## Acceptance Criteria
- `make help` displays all commands
- `make dev` runs complete startup sequence
- Preflight checks catch missing prerequisites
- Port-forwards run in background with PIDs saved
- `make teardown` cleans up completely
- `make logs` streams from all pods
- Scripts are POSIX-compatible
- Error messages are clear and actionable
- All scripts have proper error handling


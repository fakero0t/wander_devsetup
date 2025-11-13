#!/bin/bash
set -e

NAMESPACE="wander-dev"
MAX_ATTEMPTS=60
INTERVAL=5

echo "⏳ Waiting for all services to be healthy..."
echo ""

wait_for_pod() {
  local SERVICE=$1
  local PORT=$2
  local ATTEMPTS=0
  local START_TIME=$(date +%s)
  
  echo "  📦 $SERVICE: Waiting for pod to be ready..."
  
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    local ELAPSED=$(( $(date +%s) - START_TIME ))
    local POD_STATUS=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
    local POD_READY=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    local POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "unknown")
    
    echo "    [Attempt $((ATTEMPTS + 1))/$MAX_ATTEMPTS] [${ELAPSED}s elapsed] $SERVICE ($POD_NAME): Status=$POD_STATUS, Ready=$POD_READY"
    
    if [ "$POD_STATUS" = "Running" ]; then
      # For postgres and redis, check if actually ready (not just running)
      if [ "$SERVICE" = "postgres" ] || [ "$SERVICE" = "redis" ]; then
        if [ "$POD_READY" = "true" ]; then
          echo "  ✅ $SERVICE: ready (took ${ELAPSED}s)"
          return 0
        else
          echo "    ⏳ $SERVICE: Running but not ready yet (still initializing)..."
        fi
      else
        # For API and frontend, check Ready status (Kubernetes readiness probes handle health checks)
        if [ "$POD_READY" = "true" ]; then
          echo "  ✅ $SERVICE: ready (took ${ELAPSED}s)"
          return 0
        else
          echo "    ⏳ $SERVICE: Running but not ready yet (readiness probe checking)..."
        fi
      fi
    elif [ "$POD_STATUS" = "NotFound" ]; then
      echo "    ⏳ $SERVICE: Pod not found yet, waiting..."
    elif [ "$POD_STATUS" = "Pending" ]; then
      # Show detailed error every 10 attempts or on first attempt
      if [ $((ATTEMPTS % 10)) -eq 0 ] || [ $ATTEMPTS -eq 0 ]; then
        echo "    ⏳ $SERVICE: Pod is pending (scheduling/starting)..."
        echo "    🔍 Checking pod events for details:"
        kubectl describe pod -n $NAMESPACE -l app=$SERVICE 2>/dev/null | grep -A 10 "Events:" | head -15 || true
      else
        echo "    ⏳ $SERVICE: Pod is pending (scheduling/starting)..."
      fi
    elif [ "$POD_STATUS" = "CrashLoopBackOff" ] || [ "$POD_STATUS" = "Error" ]; then
      echo "    ❌ $SERVICE: Pod in error state: $POD_STATUS"
      kubectl logs -n $NAMESPACE -l app=$SERVICE --tail=20
      return 1
    fi
    
    ATTEMPTS=$((ATTEMPTS + 1))
    sleep $INTERVAL
  done
  
  echo "  ❌ $SERVICE: failed to start after $MAX_ATTEMPTS attempts ($((MAX_ATTEMPTS * INTERVAL))s)"
  echo "    Showing recent logs:"
  kubectl logs -n $NAMESPACE -l app=$SERVICE --tail=50
  return 1
}

# Wait for postgres
echo "🔵 Phase 1: Database Services"
echo "----------------------------------------"
wait_for_pod postgres 5432 &
PG_PID=$!

# Wait for redis
wait_for_pod redis 6379 &
REDIS_PID=$!

# Wait for database services first
wait $PG_PID || exit 1
wait $REDIS_PID || exit 1

echo ""
echo "🔵 Phase 2: Application Services"
echo "----------------------------------------"

# Now wait for application services
wait_for_pod api 4000 &
API_PID=$!

wait_for_pod frontend 3000 &
FRONTEND_PID=$!

# Wait for all
wait $API_PID || exit 1
wait $FRONTEND_PID || exit 1

echo ""
echo "✅ All services are healthy!"
exit 0

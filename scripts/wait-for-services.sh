#!/bin/bash
set -e

NAMESPACE="wander-dev"
MAX_ATTEMPTS=60
INTERVAL=5

echo "⏳ Waiting for all services to be healthy..."

wait_for_pod() {
  local SERVICE=$1
  local PORT=$2
  local ATTEMPTS=0
  
  echo "  ⏳ $SERVICE: starting..."
  
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    if kubectl get pods -n $NAMESPACE -l app=$SERVICE 2>/dev/null | grep -q "Running"; then
      # For postgres and redis, just check if running
      if [ "$SERVICE" = "postgres" ] || [ "$SERVICE" = "redis" ]; then
        echo "  ✅ $SERVICE: ready"
        return 0
      fi
      # For API and frontend, check health endpoint
      if kubectl exec -n $NAMESPACE deployment/$SERVICE -- curl -f http://localhost:${PORT}/health 2>/dev/null >&2; then
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


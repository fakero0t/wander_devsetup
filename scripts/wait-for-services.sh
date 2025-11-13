#!/bin/bash
set -e

NAMESPACE="wander-dev"
MAX_ATTEMPTS=60
INTERVAL=5

# Progress indicator function
show_progress() {
  local current=$1
  local total=$2
  local service=$3
  local percent=$((current * 100 / total))
  local filled=$((percent / 2))
  local empty=$((50 - filled))
  
  # Ensure filled doesn't exceed 50
  if [ $filled -gt 50 ]; then
    filled=50
    empty=0
  fi
  
  printf "\r  ["
  if [ $filled -gt 0 ]; then
    printf "%${filled}s" | tr ' ' '█'
  fi
  if [ $empty -gt 0 ]; then
    printf "%${empty}s" | tr ' ' '░'
  fi
  printf "] %3d%% %s" "$percent" "$service"
}

wait_for_pod() {
  local SERVICE=$1
  local PORT=$2
  local ATTEMPTS=0
  local START_TIME=$(date +%s)
  local LAST_STATUS=""
  
  # Friendly service names
  local SERVICE_NAME=""
  case $SERVICE in
    postgres) SERVICE_NAME="Database" ;;
    redis) SERVICE_NAME="Cache" ;;
    api) SERVICE_NAME="API Server" ;;
    frontend) SERVICE_NAME="Frontend" ;;
    *) SERVICE_NAME="$SERVICE" ;;
  esac
  
  printf "  📦 Starting $SERVICE_NAME..."
  
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    local ELAPSED=$(( $(date +%s) - START_TIME ))
    local POD_STATUS=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
    local POD_READY=$(kubectl get pods -n $NAMESPACE -l app=$SERVICE -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    
    # Only show progress if status changed or every 5 attempts
    if [ "$POD_STATUS" != "$LAST_STATUS" ] || [ $((ATTEMPTS % 5)) -eq 0 ]; then
      show_progress $ATTEMPTS $MAX_ATTEMPTS "$SERVICE_NAME"
      LAST_STATUS="$POD_STATUS"
    fi
    
    if [ "$POD_STATUS" = "Running" ]; then
      if [ "$POD_READY" = "true" ]; then
        printf "\r  ✅ $SERVICE_NAME is ready (${ELAPSED}s)\n"
        return 0
      else
        # Health check in progress
        if [ "$SERVICE" = "postgres" ] || [ "$SERVICE" = "redis" ]; then
          # Database services initializing
          : # Silent wait
        else
          # Application services - health check running
          : # Silent wait
        fi
      fi
    elif [ "$POD_STATUS" = "CrashLoopBackOff" ] || [ "$POD_STATUS" = "Error" ]; then
      printf "\r  ❌ $SERVICE_NAME failed to start\n"
      echo ""
      echo "  Error Details:"
      echo "  ──────────────────────────────────────"
      kubectl logs -n $NAMESPACE -l app=$SERVICE --tail=10 2>/dev/null | sed 's/^/  /' || echo "  Unable to retrieve logs"
      echo ""
      echo "  💡 Tip: Check the logs above for error messages"
      echo "  💡 Run 'make logs-$SERVICE' for more details"
      return 1
    elif [ "$POD_STATUS" = "Pending" ]; then
      # Only show details on first attempt or every 20 attempts
      if [ $ATTEMPTS -eq 0 ] || [ $((ATTEMPTS % 20)) -eq 0 ]; then
        : # Silent wait
      fi
    fi
    
    ATTEMPTS=$((ATTEMPTS + 1))
    sleep $INTERVAL
  done
  
  printf "\r  ❌ $SERVICE_NAME failed to start (timeout after $((MAX_ATTEMPTS * INTERVAL))s)\n"
  echo ""
  echo "  Error Details:"
  echo "  ──────────────────────────────────────"
  kubectl logs -n $NAMESPACE -l app=$SERVICE --tail=15 2>/dev/null | sed 's/^/  /' || echo "  Unable to retrieve logs"
  echo ""
  echo "  💡 Troubleshooting:"
  echo "     • Check if all dependencies are running: make status"
  echo "     • View detailed logs: make logs-$SERVICE"
  echo "     • Restart the service: make restart"
  return 1
}

# Phase 1: Database Services
echo ""
echo "🔵 Phase 1: Starting Database Services"
echo "─────────────────────────────────────────"
wait_for_pod postgres 5432 &
PG_PID=$!

wait_for_pod redis 6379 &
REDIS_PID=$!

wait $PG_PID || exit 1
wait $REDIS_PID || exit 1

echo ""
echo "🔵 Phase 2: Starting Application Services"
echo "─────────────────────────────────────────"

wait_for_pod api 4000 &
API_PID=$!

wait_for_pod frontend 3000 &
FRONTEND_PID=$!

wait $API_PID || exit 1
wait $FRONTEND_PID || exit 1

echo ""
echo "✅ All services are healthy and ready!"
exit 0

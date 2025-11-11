#!/bin/bash

# Common error handling utilities for the Wander development environment

display_error() {
  local ERROR_TYPE=$1
  local ERROR_MSG=$2
  
  echo ""
  echo "❌ ERROR: $ERROR_TYPE"
  echo "   $ERROR_MSG"
  echo ""
}

suggest_docker_restart() {
  echo "💡 Suggested fix:"
  echo "   1. Restart Docker Desktop"
  echo "   2. Wait for it to fully start"
  echo "   3. Run 'make dev' again"
  echo ""
}

suggest_kubectl_config() {
  echo "💡 Suggested fix:"
  echo "   1. Enable Kubernetes in Docker Desktop:"
  echo "      Settings → Kubernetes → Enable Kubernetes"
  echo "   2. Wait for Kubernetes to start (green icon)"
  echo "   3. Run 'make dev' again"
  echo ""
}

suggest_port_conflict() {
  local PORT=$1
  echo "💡 Suggested fix:"
  echo "   1. Find the process using port $PORT:"
  echo "      lsof -ti:$PORT"
  echo "   2. Stop the process:"
  echo "      kill \$(lsof -ti:$PORT)"
  echo "   3. Or change the port in .env file"
  echo "   4. Run 'make dev' again"
  echo ""
}

suggest_disk_space() {
  echo "💡 Suggested fix:"
  echo "   1. Free up disk space (at least 10GB recommended)"
  echo "   2. Clean Docker images: docker system prune -a"
  echo "   3. Run 'make dev' again"
  echo ""
}

suggest_memory() {
  echo "💡 Suggested fix:"
  echo "   1. Close other applications"
  echo "   2. Increase Docker Desktop memory limit:"
  echo "      Settings → Resources → Memory (at least 4GB)"
  echo "   3. Run 'make dev' again"
  echo ""
}

handle_pod_failure() {
  local POD_NAME=$1
  echo ""
  echo "❌ Pod $POD_NAME failed to start"
  echo ""
  echo "📋 Recent logs:"
  kubectl logs -n wander-dev -l app=$POD_NAME --tail=20 2>/dev/null || echo "   No logs available"
  echo ""
  echo "💡 Suggested fix:"
  echo "   1. Check logs: make logs-$POD_NAME"
  echo "   2. Check pod status: make status"
  echo "   3. Try restarting: make restart"
  echo ""
}

handle_build_failure() {
  local SERVICE=$1
  echo ""
  echo "❌ Failed to build $SERVICE Docker image"
  echo ""
  echo "💡 Suggested fix:"
  echo "   1. Check Docker daemon is running"
  echo "   2. Verify Dockerfile exists: services/$SERVICE/Dockerfile"
  echo "   3. Check for syntax errors in Dockerfile"
  echo "   4. Try: docker build -t wander-$SERVICE:latest -f services/$SERVICE/Dockerfile ."
  echo ""
}

export -f display_error
export -f suggest_docker_restart
export -f suggest_kubectl_config
export -f suggest_port_conflict
export -f suggest_disk_space
export -f suggest_memory
export -f handle_pod_failure
export -f handle_build_failure


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


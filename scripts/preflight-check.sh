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

# Function to check if a port is in use
is_port_in_use() {
  local port=$1
  if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -an 2>/dev/null | grep -q ":$port.*LISTEN"; then
    return 0  # Port is in use
  else
    return 1  # Port is available
  fi
}

# Function to find an available port starting from a given port
find_available_port() {
  local start_port=$1
  local port=$start_port
  while [ $port -lt 65535 ]; do
    if ! is_port_in_use $port; then
      echo $port
      return 0
    fi
    port=$((port + 1))
  done
  echo ""
  return 1
}

# Function to update .env file with a new port value
update_env_port() {
  local var_name=$1
  local new_port=$2
  local env_file=".env"
  
  # Ensure .env exists (generate from config.yaml if needed)
  if [ ! -f "$env_file" ]; then
    if [ -f "config.yaml" ]; then
      node scripts/load-config.js --format env
      echo "ℹ️  Generated .env from config.yaml"
    else
      touch "$env_file"
    fi
  fi
  
  # Update or add the port variable
  if grep -q "^${var_name}=" "$env_file"; then
    # Update existing variable (works on both macOS and Linux)
    if [ "$OS" = "Darwin" ]; then
      sed -i '' "s/^${var_name}=.*/${var_name}=${new_port}/" "$env_file"
    else
      sed -i "s/^${var_name}=.*/${var_name}=${new_port}/" "$env_file"
    fi
  else
    # Add new variable
    echo "${var_name}=${new_port}" >> "$env_file"
  fi
}

# Check and adapt ports
echo ""
echo "📡 Checking and configuring ports..."

PORTS_UPDATED=0

# Function to check and configure a single port
check_and_configure_port() {
  local DEFAULT_PORT=$1
  local VAR_NAME=$2
  
  # Check current .env value if it exists
  if [ -f ".env" ] && grep -q "^${VAR_NAME}=" .env; then
    CURRENT_PORT=$(grep "^${VAR_NAME}=" .env | cut -d'=' -f2)
  else
    CURRENT_PORT=$DEFAULT_PORT
  fi
  
  if is_port_in_use $CURRENT_PORT; then
    echo "⚠️  Port $CURRENT_PORT ($VAR_NAME) is in use"
    NEW_PORT=$(find_available_port $((CURRENT_PORT + 1)))
    
    if [ -n "$NEW_PORT" ]; then
      echo "   ➜ Using port $NEW_PORT instead"
      update_env_port "$VAR_NAME" "$NEW_PORT"
      PORTS_UPDATED=1
    else
      echo "❌ Could not find an available port for $VAR_NAME"
      exit 1
    fi
  else
    echo "✅ Port $CURRENT_PORT ($VAR_NAME) is available"
    # Ensure the port is set in .env even if it's the default
    if [ ! -f ".env" ] || ! grep -q "^${VAR_NAME}=" .env; then
      update_env_port "$VAR_NAME" "$CURRENT_PORT"
    fi
  fi
}

# Check each port
check_and_configure_port 3000 "FRONTEND_PORT"
check_and_configure_port 4000 "API_PORT"
check_and_configure_port 5432 "POSTGRES_PORT"
check_and_configure_port 6379 "REDIS_PORT"

if [ $PORTS_UPDATED -eq 1 ]; then
  echo ""
  echo "ℹ️  Port configuration updated in .env file"
  echo "   Review .env to see the new port assignments"
fi

echo ""
echo "✅ All preflight checks passed"
exit 0


#!/bin/bash
set -e

# Parse arguments
SKIP_PORTS=false
PORTS_ONLY=false
if [ "$1" = "--skip-ports" ]; then
  SKIP_PORTS=true
elif [ "$1" = "--ports-only" ]; then
  PORTS_ONLY=true
fi

# Detect OS
OS=$(uname -s)

# Check Docker
printf "  Checking Docker... "
if ! command -v docker &> /dev/null || ! docker ps &> /dev/null; then
  echo "❌"
  echo ""
  echo "  Error: Docker is not running"
  echo "  ──────────────────────────────────────"
  echo "  💡 Solution: Start Docker Desktop and try again"
  echo ""
  exit 1
fi
echo "✓"

# Check kubectl
printf "  Checking Kubernetes... "
if ! command -v kubectl &> /dev/null; then
  echo "❌"
  echo ""
  echo "  Error: kubectl not found"
  echo "  ──────────────────────────────────────"
  echo "  💡 Solution: Install kubectl:"
  echo "     • macOS: brew install kubectl"
  echo "     • Linux: See https://kubernetes.io/docs/tasks/tools/"
  echo ""
  exit 1
fi
if ! kubectl cluster-info &> /dev/null; then
  echo "❌"
  echo ""
  echo "  Error: Kubernetes cluster not available"
  echo "  ──────────────────────────────────────"
  echo "  💡 Solution:"
  echo "     • Enable Kubernetes in Docker Desktop, or"
  echo "     • Start Minikube: minikube start"
  echo ""
  exit 1
fi
echo "✓"

# Check envsubst
printf "  Checking tools... "
if ! command -v envsubst &> /dev/null; then
  echo "❌"
  echo ""
  echo "  Error: envsubst not found"
  echo "  ──────────────────────────────────────"
  echo "  💡 Solution: Install gettext package"
  echo "     • macOS: brew install gettext"
  echo "     • Linux: sudo apt-get install gettext-base"
  echo ""
  exit 1
fi
echo "✓"

# Skip basic checks if --ports-only is specified
if [ "$PORTS_ONLY" = true ]; then
  # Skip to port checks section - don't do basic checks
  :
elif [ "$SKIP_PORTS" = true ]; then
  # Check disk space (silent warning)
  DISK_AVAIL=$(df -k . | awk 'NR==2 {print $4}' 2>/dev/null || echo "0")
  if [ "$DISK_AVAIL" -lt 10485760 ] && [ "$DISK_AVAIL" != "0" ]; then
    echo "  ⚠️  Warning: Low disk space (< 10GB available)"
  fi

  # Check memory (silent warning)
  if [ "$OS" = "Darwin" ]; then
    MEM_TOTAL=$(sysctl -n hw.memsize 2>/dev/null | awk '{print $1/1024/1024/1024}' || echo "0")
  else
    MEM_TOTAL=$(free -g 2>/dev/null | awk 'NR==2 {print $2}' || echo "0")
  fi
  if [ "${MEM_TOTAL%.*}" -lt 4 ] && [ "${MEM_TOTAL%.*}" != "0" ]; then
    echo "  ⚠️  Warning: Low memory (< 4GB available)"
  fi
  echo ""
  echo "✅ All preflight checks passed"
  exit 0
else
  # Check disk space (silent warning)
  DISK_AVAIL=$(df -k . | awk 'NR==2 {print $4}' 2>/dev/null || echo "0")
  if [ "$DISK_AVAIL" -lt 10485760 ] && [ "$DISK_AVAIL" != "0" ]; then
    echo "  ⚠️  Warning: Low disk space (< 10GB available)"
  fi

  # Check memory (silent warning)
  if [ "$OS" = "Darwin" ]; then
    MEM_TOTAL=$(sysctl -n hw.memsize 2>/dev/null | awk '{print $1/1024/1024/1024}' || echo "0")
  else
    MEM_TOTAL=$(free -g 2>/dev/null | awk 'NR==2 {print $2}' || echo "0")
  fi
  if [ "${MEM_TOTAL%.*}" -lt 4 ] && [ "${MEM_TOTAL%.*}" != "0" ]; then
    echo "  ⚠️  Warning: Low memory (< 4GB available)"
  fi
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

# Check and adapt ports (run if ports-only OR if not skipping)
if [ "$PORTS_ONLY" = true ] || [ "$SKIP_PORTS" = false ]; then
  echo ""
  echo "📡 Checking and configuring ports..."

  # Load config if .config.env doesn't exist but config.yaml does
  if [ ! -f ".config.env" ] && [ -f "config.yaml" ]; then
    if command -v node &> /dev/null; then
      node scripts/load-config.js >/dev/null 2>&1 || true
    fi
  fi

  PORTS_UPDATED=0

  # Function to get port from config
  get_port_from_config() {
    local VAR_NAME=$1
    local DEFAULT_PORT=$2
    
    # Map POSTGRES_PORT to DATABASE_PORT for .config.env lookup
    local CONFIG_VAR_NAME="$VAR_NAME"
    if [ "$VAR_NAME" = "POSTGRES_PORT" ]; then
      CONFIG_VAR_NAME="DATABASE_PORT"
    fi
    
    # First try .config.env (generated from config.yaml)
    if [ -f ".config.env" ]; then
      # .config.env has format: export FRONTEND_PORT="3005"
      local port=$(grep "^export ${CONFIG_VAR_NAME}=" .config.env 2>/dev/null | cut -d'"' -f2)
      if [ -n "$port" ]; then
        echo "$port"
        return 0
      fi
    fi
    
    # Fallback to .env file
    if [ -f ".env" ] && grep -q "^${VAR_NAME}=" .env; then
      local port=$(grep "^${VAR_NAME}=" .env | cut -d'=' -f2)
      if [ -n "$port" ]; then
        echo "$port"
        return 0
      fi
    fi
    
    # Use default
    echo "$DEFAULT_PORT"
  }

  # Function to check and configure a single port
  check_and_configure_port() {
    local DEFAULT_PORT=$1
    local VAR_NAME=$2
    
    # Get port from config file or use default
    CURRENT_PORT=$(get_port_from_config "$VAR_NAME" "$DEFAULT_PORT")
    
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
  echo "✅ Port checks completed"
fi

# Exit if we were only doing port checks or skipping ports
if [ "$PORTS_ONLY" = true ] || [ "$SKIP_PORTS" = true ]; then
  exit 0
fi

# If we get here, we did all checks including ports
echo ""
echo "✅ All preflight checks passed"
exit 0


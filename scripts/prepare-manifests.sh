#!/bin/bash
set -e

# Load config and export variables
eval $(node scripts/load-config.js --format shell-export)

NODE_ENV=${NODE_ENV:-development}
WORKSPACE_PATH=${WORKSPACE_PATH:-$(pwd)}

echo "🔨 Preparing Kubernetes manifests for $NODE_ENV environment..."

# Create generated directory
mkdir -p infra/generated

# Export variables for envsubst
export NODE_ENV
export WORKSPACE_PATH

# Read seed.sql and prepare for ConfigMap (indent each line with 4 spaces)
export SEED_SQL_CONTENT=$(cat db/init/seed.sql | sed 's/^/    /')

# Generate conditional blocks based on environment
if [ "$NODE_ENV" = "development" ]; then
  # Development: use dev commands
  # Note: hostPath volumes removed - they don't work in Minikube/Docker Desktop VMs
  # Hot-reloading requires rebuilding images or using alternative methods
  export DEV_API_VOLUME=""
  export DEV_VOLUME_MOUNT=""
  export API_COMMAND='["npm", "run", "dev"]'
  export DEV_COMMAND='["npm", "run", "dev"]'
else
  # Production: no volumes, use production commands
  export DEV_API_VOLUME=""
  export DEV_VOLUME_MOUNT=""
  export API_COMMAND='["npm", "start"]'
  export DEV_COMMAND='["serve", "-s", "dist", "-l", "3000", "--no-clipboard"]'
fi

# Process all YAML files
# Include all config variables in envsubst
for file in infra/k8s/*.yaml; do
  filename=$(basename "$file")
  envsubst '$NODE_ENV $WORKSPACE_PATH $DEV_API_VOLUME $API_COMMAND $DEV_VOLUME_MOUNT $DEV_COMMAND $SEED_SQL_CONTENT $DATABASE_HOST $DATABASE_PORT $DATABASE_NAME $DATABASE_USER $DATABASE_PASSWORD $DATABASE_POOL_SIZE $API_HOST $API_PORT $API_DEBUG_PORT $API_LOG_LEVEL $FRONTEND_HOST $FRONTEND_PORT $VITE_API_URL $REDIS_HOST $REDIS_PORT $ENVIRONMENT' < "$file" > "infra/generated/$filename"
  echo "  ✅ Generated infra/generated/$filename"
done

echo "✅ Manifests prepared successfully"


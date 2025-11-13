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

# Read seed.sql and prepare for ConfigMap (indent each line with 4 spaces)
export SEED_SQL_CONTENT=$(cat db/init/seed.sql | sed 's/^/    /')

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
  export DEV_VOLUME_MOUNT=$(cat <<EOF
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
  export DEV_COMMAND='["npm", "run", "dev"]'
else
  # Production: no volumes, use production commands
  export DEV_API_VOLUME=""
  export DEV_VOLUME_MOUNT=""
  export API_COMMAND='["npm", "start"]'
  export DEV_COMMAND='["serve", "-s", "dist", "-l", "3000", "--no-clipboard"]'
fi

# Process all YAML files
for file in infra/k8s/*.yaml; do
  filename=$(basename "$file")
  envsubst '$NODE_ENV $WORKSPACE_PATH $DEV_API_VOLUME $API_COMMAND $DEV_VOLUME_MOUNT $DEV_COMMAND $SEED_SQL_CONTENT' < "$file" > "infra/generated/$filename"
  echo "  ✅ Generated infra/generated/$filename"
done

echo "✅ Manifests prepared successfully"


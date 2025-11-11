# PR #6: Kubernetes Manifests

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

**Goal:** Create all Kubernetes YAML manifests for deploying services to local cluster.

## Files to Create

**infra/k8s/namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: wander-dev
```

**infra/k8s/configmap.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: wander-config
  namespace: wander-dev
data:
  DATABASE_HOST: postgres
  DATABASE_PORT: "5432"
  DATABASE_NAME: wander_dev
  DATABASE_USER: postgres
  DATABASE_POOL_SIZE: "10"
  API_HOST: 0.0.0.0
  API_PORT: "4000"
  API_DEBUG_PORT: "9229"
  API_LOG_LEVEL: debug
  NODE_ENV: ${NODE_ENV}
  FRONTEND_HOST: 0.0.0.0
  FRONTEND_PORT: "3000"
  REDIS_HOST: redis
  REDIS_PORT: "6379"
  ENVIRONMENT: development
```

**infra/k8s/postgres.yaml:**
- Deployment: postgres:14-alpine image, 1 replica
- Environment variables from ConfigMap + DATABASE_PASSWORD as plain env
- Volume mount for seed script (use hostPath to db/init/seed.sql)
- Resources: requests 200m CPU/256Mi RAM, limits 1000m CPU/512Mi RAM
- Readiness probe: exec pg_isready, initialDelaySeconds 15s
- Liveness probe: exec pg_isready, initialDelaySeconds 20s
- Service: ClusterIP on port 5432

**infra/k8s/redis.yaml:**
- Deployment: redis:7-alpine, 1 replica
- Resources: requests 50m CPU/128Mi RAM, limits 250m CPU/256Mi RAM
- Readiness probe: exec redis-cli ping, initialDelaySeconds 5s
- Liveness probe: exec redis-cli ping, initialDelaySeconds 10s
- Service: ClusterIP on port 6379

**infra/k8s/api.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: wander-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: wander-api:latest
        imagePullPolicy: IfNotPresent
        command: ${API_COMMAND}
        ports:
        - containerPort: 4000
        - containerPort: 9229
        env:
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: wander-config
              key: DATABASE_HOST
        - name: DATABASE_PORT
          valueFrom:
            configMapKeyRef:
              name: wander-config
              key: DATABASE_PORT
        - name: DATABASE_NAME
          valueFrom:
            configMapKeyRef:
              name: wander-config
              key: DATABASE_NAME
        - name: DATABASE_USER
          valueFrom:
            configMapKeyRef:
              name: wander-config
              key: DATABASE_USER
        - name: DATABASE_PASSWORD
          value: "dev_password"
        - name: REDIS_HOST
          valueFrom:
            configMapKeyRef:
              name: wander-config
              key: REDIS_HOST
        - name: REDIS_PORT
          valueFrom:
            configMapKeyRef:
              name: wander-config
              key: REDIS_PORT
        - name: NODE_ENV
          value: "${NODE_ENV}"
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 4000
          initialDelaySeconds: 20
          periodSeconds: 5
          timeoutSeconds: 5
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /health
            port: 4000
          initialDelaySeconds: 25
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
${DEV_API_VOLUME}
---
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: wander-dev
spec:
  selector:
    app: api
  ports:
  - port: 4000
    targetPort: 4000
  type: ClusterIP
```

**infra/k8s/frontend.yaml:**
- Deployment: wander-frontend:latest, 1 replica
- Environment: VITE_API_URL from ConfigMap (http://localhost:4000 for dev)
- Volume mounts: ${DEV_VOLUME_MOUNT} for development
- Resources: requests 50m CPU/128Mi RAM, limits 250m CPU/256Mi RAM
- Readiness probe: httpGet /:3000, initialDelaySeconds 10s
- Liveness probe: httpGet /:3000, initialDelaySeconds 15s
- Command override in dev: ${DEV_COMMAND}
- Service: ClusterIP on port 3000

**Notes in comments:**
- All YAML files include comments indicating they use envsubst for variable substitution
- Template variables: ${NODE_ENV}, ${DEV_VOLUME_MOUNT}, ${DEV_COMMAND}, ${WORKSPACE_PATH}
- Files are templates, actual generated files go to infra/generated/

## Acceptance Criteria
- All manifests are valid YAML
- Template variables clearly marked
- Resource limits match PRD specifications
- Health check timing matches PRD specifications
- All services use ClusterIP
- Namespace is wander-dev


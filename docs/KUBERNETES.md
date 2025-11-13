# Wander - Kubernetes Documentation

This guide explains Kubernetes concepts and configuration for the Wander application, aimed at developers new to Kubernetes.

## What is Kubernetes?

**Kubernetes (K8s)** is a container orchestration platform that automates deployment, scaling, and management of containerized applications.

**Key Benefits:**
- **Self-healing**: Automatically restarts failed containers
- **Service discovery**: Services find each other automatically
- **Load balancing**: Distributes traffic across multiple instances
- **Rolling updates**: Update applications with zero downtime
- **Resource management**: Ensures fair resource allocation

## Why Kubernetes for Local Development?

**Production Parity:**
- Develop in the same environment you'll deploy to
- Catch issues early (networking, resource limits, health checks)
- Practice Kubernetes before production

**Learning:**
- Understand pods, services, deployments
- Practice with kubectl commands
- Prepare for cloud deployments (EKS, GKE, AKS)

## Minikube Overview

**Minikube** is a tool that runs a single-node Kubernetes cluster on your local machine.

**Start Minikube:**
```bash
minikube start --memory=4096 --cpus=2
```

**Useful Commands:**
```bash
minikube status        # Check if running
minikube stop          # Stop the cluster
minikube delete        # Delete the cluster
minikube dashboard     # Open Kubernetes dashboard
minikube ip            # Get cluster IP
```

## Kubernetes Core Concepts

### Namespaces

Namespaces isolate resources within a cluster. Wander uses the `wander-dev` namespace.

**Why Use Namespaces:**
- Separate development environments
- Avoid resource name conflicts
- Organize related resources

**View Namespaces:**
```bash
kubectl get namespaces
```

**All Wander commands target `wander-dev`:**
```bash
kubectl get pods -n wander-dev
```

### Pods

A **Pod** is the smallest deployable unit in Kubernetes. It wraps one or more containers.

**Wander Pods:**
- `postgres-xxxxx`: PostgreSQL database
- `redis-xxxxx`: Redis cache
- `api-xxxxx`: Backend API
- `frontend-xxxxx`: React frontend

**View Pods:**
```bash
kubectl get pods -n wander-dev
```

**Describe Pod:**
```bash
kubectl describe pod -n wander-dev postgres-xxxxx
```

**Pod Lifecycle:**
```
Pending → ContainerCreating → Running → Succeeded/Failed
```

### Deployments

A **Deployment** manages a set of identical pods. It ensures the desired number of replicas are running.

**Wander Deployments:**
- `postgres`: 1 replica
- `redis`: 1 replica
- `api`: 1 replica
- `frontend`: 1 replica

**View Deployments:**
```bash
kubectl get deployments -n wander-dev
```

**Scale Deployment (if needed):**
```bash
kubectl scale deployment api -n wander-dev --replicas=2
```

**Features:**
- Automatic pod replacement if crashed
- Rolling updates for zero-downtime deployments
- Rollback support

### Services

A **Service** provides stable networking for pods. Pods get dynamic IPs; services provide stable DNS names.

**Wander Services:**
- `postgres`: Internal database access (port 5432)
- `redis`: Internal cache access (port 6379)
- `api`: Internal API access (port 4000)
- `frontend`: Internal frontend access (port 3000)

**View Services:**
```bash
kubectl get services -n wander-dev
```

**Service Types:**
- **ClusterIP** (used by Wander): Internal cluster access only
- **NodePort**: Exposes on each node's IP
- **LoadBalancer**: Cloud provider load balancer (AWS ELB, etc.)

### ConfigMaps

**ConfigMaps** store non-sensitive configuration data as key-value pairs.

**Wander ConfigMap:**
```bash
kubectl get configmap wander-config -n wander-dev -o yaml
```

**Usage:**
- Environment variables for all services
- Database connection details
- API/frontend configuration

**Benefits:**
- Centralized configuration
- Easy to update
- No code changes needed for config changes

### Secrets (Not Used in Dev)

**Secrets** store sensitive data (passwords, tokens) with base64 encoding.

**Production Use:**
- Database passwords
- API keys
- TLS certificates

**Why Not in Dev:**
- Development uses hardcoded passwords
- Easier iteration (no base64 encoding)
- ConfigMap is sufficient for non-sensitive dev data

## Service Discovery

Kubernetes provides automatic DNS for services within a cluster.

### DNS Names

**Full DNS Name:**
```
<service-name>.<namespace>.svc.cluster.local
```

**Wander Service DNS:**
- `postgres.wander-dev.svc.cluster.local:5432`
- `redis.wander-dev.svc.cluster.local:6379`
- `api.wander-dev.svc.cluster.local:4000`
- `frontend.wander-dev.svc.cluster.local:3000`

**Short Names (Same Namespace):**
Within the `wander-dev` namespace, services can use short names:
- `postgres:5432`
- `redis:6379`
- `api:4000`

**Example (API Connecting to Database):**
```javascript
const client = new Pool({
  host: 'postgres',  // Short name works!
  port: 5432,
  database: 'wander_dev'
});
```

## Health Probes

Health probes help Kubernetes manage application lifecycle.

### Readiness Probes

**Purpose:** Determine if a pod is ready to receive traffic.

**Behavior:**
- Failed probe → Pod removed from service endpoints
- Passed probe → Pod added back to service endpoints

**Use Cases:**
- Waiting for database connection
- Loading configuration
- Warming up caches

**Example (API):**
```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 4000
  initialDelaySeconds: 20  # Wait 20s before first check
  periodSeconds: 5         # Check every 5s
  failureThreshold: 3      # Fail after 3 consecutive failures
```

### Liveness Probes

**Purpose:** Determine if a pod is healthy and should keep running.

**Behavior:**
- Failed probe → Kubernetes restarts the pod
- Passed probe → Pod continues running

**Use Cases:**
- Detecting deadlocks
- Detecting memory leaks
- Application crash detection

**Example (API):**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 4000
  initialDelaySeconds: 25  # Wait 25s before first check
  periodSeconds: 10        # Check every 10s
  failureThreshold: 3      # Restart after 3 consecutive failures
```

### Probe Types

1. **HTTP Probe**: HTTP GET request (most common)
2. **TCP Probe**: TCP socket connection
3. **Exec Probe**: Run command inside container

**Wander Uses:**
- **API/Frontend**: HTTP probes
- **PostgreSQL**: `pg_isready` command probe
- **Redis**: `redis-cli ping` command probe

## Resource Limits

Kubernetes can enforce CPU and memory limits on pods.

### Requests vs. Limits

**Requests:** Guaranteed resources
- Used for scheduling decisions
- Pod only schedules on nodes with available resources

**Limits:** Maximum allowed resources
- Pod is throttled if exceeding CPU limit
- Pod is killed if exceeding memory limit

### Wander Resource Configuration

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|------------|-----------|----------------|--------------|
| API | 100m | 500m | 256Mi | 512Mi |
| Frontend | 50m | 200m | 128Mi | 256Mi |
| PostgreSQL | 100m | 1000m | 256Mi | 512Mi |
| Redis | 50m | 200m | 128Mi | 256Mi |

**Units:**
- **CPU**: `100m` = 0.1 CPU core, `1000m` = 1 full core
- **Memory**: `256Mi` = 256 mebibytes, `1Gi` = 1 gibibyte

**Example (API Deployment):**
```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Why Conservative Limits?

Minikube default: 2 CPUs, 4GB RAM

**Total Wander Usage:**
- Requests: 300m CPU, 768Mi RAM
- Limits: 1900m CPU, 1536Mi RAM

Leaves headroom for:
- Minikube system components
- Host OS
- Other applications

## Port Forwarding

Kubernetes services are internal by default. Port forwarding exposes them to localhost.

### Manual Port Forwarding

```bash
# API
kubectl port-forward -n wander-dev service/api 4000:4000

# Frontend
kubectl port-forward -n wander-dev service/frontend 3000:3000

# PostgreSQL
kubectl port-forward -n wander-dev service/postgres 5432:5432
```

### Automatic (via Makefile)

`make dev` automatically sets up port forwarding in the background:

```bash
kubectl port-forward -n wander-dev service/api 4000:4000 &
kubectl port-forward -n wander-dev service/frontend 3000:3000 &
```

### Stopping Port Forwards

```bash
# Kill all port-forwards
pkill -f "kubectl port-forward"
```

## Development vs. Production Configuration

### Development (Wander)

**Characteristics:**
- Single replicas (1 pod per service)
- Hardcoded passwords in manifests
- Debug ports exposed (API port 9229)
- ClusterIP services + port forwarding
- hostPath volumes for seed scripts
- Lower resource limits

**Configuration:**
```yaml
# infra/k8s/api.yaml
replicas: 1
env:
  - name: DATABASE_PASSWORD
    value: "dev_password"  # ❌ Never in production!
```

### Production Changes Needed

**Security:**
- Use Kubernetes Secrets for passwords
- Implement TLS/SSL
- Add authentication and authorization
- Remove debug ports
- Use private container registry

**Scalability:**
- Multiple replicas (2-10+ per service)
- Horizontal Pod Autoscaler
- LoadBalancer services
- Persistent volumes (not hostPath)

**Reliability:**
- Database replication and backups
- Redis persistence
- Monitoring (Prometheus, Grafana)
- Alerting (PagerDuty, Slack)
- Log aggregation (ELK, CloudWatch)

**Example Production Changes:**
```yaml
# Production api.yaml
replicas: 3  # Multiple instances

env:
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: wander-secrets
        key: db-password

resources:
  requests:
    cpu: 500m      # Higher resources
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi
```

## Common kubectl Commands

### Viewing Resources

```bash
# List all resources
kubectl get all -n wander-dev

# Get pods
kubectl get pods -n wander-dev

# Get services
kubectl get services -n wander-dev

# Get deployments
kubectl get deployments -n wander-dev

# Get configmaps
kubectl get configmaps -n wander-dev

# Wide output (more details)
kubectl get pods -n wander-dev -o wide
```

### Inspecting Resources

```bash
# Describe pod (events, conditions, etc.)
kubectl describe pod -n wander-dev api-xxxxx

# Get pod logs
kubectl logs -n wander-dev api-xxxxx

# Follow logs (tail -f)
kubectl logs -n wander-dev api-xxxxx -f

# Previous pod logs (if restarted)
kubectl logs -n wander-dev api-xxxxx --previous
```

### Interactive Access

```bash
# Exec into pod
kubectl exec -it -n wander-dev api-xxxxx -- /bin/sh

# Run single command
kubectl exec -n wander-dev postgres-xxxxx -- psql -U postgres -d wander_dev -c "SELECT COUNT(*) FROM users;"
```

### Managing Resources

```bash
# Apply manifests
kubectl apply -f infra/generated/

# Delete resources
kubectl delete -f infra/generated/

# Delete namespace (removes all resources)
kubectl delete namespace wander-dev

# Restart deployment
kubectl rollout restart deployment api -n wander-dev

# Check rollout status
kubectl rollout status deployment api -n wander-dev
```

### Debugging

```bash
# Get pod events
kubectl get events -n wander-dev --sort-by='.lastTimestamp'

# Describe service endpoints
kubectl describe endpoints api -n wander-dev

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup postgres.wander-dev.svc.cluster.local

# Check resource usage
kubectl top pods -n wander-dev
```

## Volumes and Storage

### ConfigMap Volumes (Development)

Wander uses **ConfigMap** to mount the seed script into the PostgreSQL pod. This approach is cross-platform and works in any Kubernetes environment (Minikube, Docker Desktop, cloud, etc.).

**Example:**
```yaml
volumeMounts:
  - name: seed-script
    mountPath: /docker-entrypoint-initdb.d
    readOnly: true

volumes:
  - name: seed-script
    configMap:
      name: wander-seed-script
```

**Benefits:**
- Works on any OS (macOS, Linux, Windows)
- Works in any Kubernetes environment (Minikube, Docker Desktop, kind, cloud)
- No host filesystem dependencies
- Version controlled (seed.sql is embedded in the ConfigMap)
- Portable across different machines

The seed script (`db/init/seed.sql`) is automatically embedded into the ConfigMap during manifest generation via `prepare-manifests.sh`.

### Production Storage

Production should use:
- **PersistentVolumeClaims (PVC)**: Request storage from cluster
- **PersistentVolumes (PV)**: Actual storage backed by cloud provider
- **StorageClasses**: Define types of storage (SSD, HDD, etc.)

**Example PVC:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
```

## Networking

### Internal Communication

Services communicate using cluster DNS and ClusterIP:

```
Frontend → API → PostgreSQL
Frontend → API → Redis
```

**No External Access by Default:**
- Database is not exposed outside cluster
- Redis is not exposed outside cluster
- Only API and Frontend are port-forwarded for local development

### Production Ingress

Production would use **Ingress** for external access:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wander-ingress
spec:
  rules:
  - host: wander.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api
            port:
              number: 4000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 3000
```

## Environment Variable Templating

Wander uses `envsubst` to template Kubernetes manifests with environment variables.

**Template (infra/k8s/configmap.yaml):**
```yaml
data:
  NODE_ENV: ${NODE_ENV}
  DATABASE_HOST: postgres
```

**Generated (infra/generated/configmap.yaml):**
```yaml
data:
  NODE_ENV: development
  DATABASE_HOST: postgres
```

**Script:**
```bash
./scripts/prepare-manifests.sh
```

**Benefits:**
- Single manifest source
- Environment-specific values
- Reduces duplication

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n wander-dev

# Describe pod for events
kubectl describe pod -n wander-dev <pod-name>

# Check logs
kubectl logs -n wander-dev <pod-name>
```

**Common Issues:**
- Image not found: Ensure `eval $(minikube docker-env)` was run before build
- CrashLoopBackOff: Application is crashing, check logs
- ImagePullBackOff: Image doesn't exist or wrong name

### Service Not Reachable

```bash
# Check service
kubectl get service -n wander-dev <service-name>

# Check endpoints
kubectl get endpoints -n wander-dev <service-name>
```

**Common Issues:**
- No endpoints: Pods not ready (check readiness probes)
- Wrong port: Verify service port matches container port

### Resource Exhaustion

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n wander-dev
```

**Solutions:**
- Reduce resource requests
- Increase Minikube memory/CPU
- Scale down replicas

## Best Practices

### Labels and Selectors

Use consistent labels for organization:

```yaml
metadata:
  labels:
    app: api
    tier: backend
    environment: development
```

### Health Checks

Always implement health checks:
- Readiness: Check dependencies (DB, Redis)
- Liveness: Simple check (return 200)

### Resource Limits

Always set resource limits:
- Prevents resource starvation
- Enables fair scheduling
- Improves stability

### Graceful Shutdown

Handle SIGTERM for graceful shutdown:
- Close database connections
- Finish in-flight requests
- Clean up resources

### Logging

Log to stdout/stderr:
- Kubernetes collects logs automatically
- Use `kubectl logs` to view
- Integrate with log aggregation tools

## Next Steps

### Learning Resources

- [Kubernetes Official Tutorials](https://kubernetes.io/docs/tutorials/)
- [Kubernetes by Example](http://kubernetesbyexample.com/)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)

### Cloud Deployment

When ready for cloud:
- **AWS**: Amazon EKS
- **Google Cloud**: Google GKE
- **Azure**: Azure AKS
- **DigitalOcean**: DOKS

### Advanced Topics

- Helm charts for templating
- Operators for complex applications
- Service meshes (Istio, Linkerd)
- GitOps with ArgoCD or Flux

## Related Documentation

- [Setup Guide](./SETUP.md) - Getting started with Kubernetes locally
- [Architecture](./ARCHITECTURE.md) - How Kubernetes fits into system
- [Troubleshooting](./TROUBLESHOOTING.md) - Kubernetes-specific issues


# Wander - Troubleshooting Guide

This guide helps you diagnose and fix common issues with the Wander development environment.

## Quick Diagnostics

Before diving into specific issues, run these commands to check system status:

```bash
# Check all pods status
make status

# View recent logs from all services
make logs

# Check health endpoints
curl http://localhost:4000/health
curl http://localhost:4000/health/ready
```

## Common Error Scenarios

### Error: Port Already in Use

**Symptom:**
```
Error: listen tcp :4000: bind: address already in use
Error: listen tcp :3000: bind: address already in use
```

**Cause:**
Another process is using the port, or previous port-forwards are still running.

**Solution 1: Kill port-forward processes**
```bash
# Kill all kubectl port-forward processes
pkill -f "kubectl port-forward"

# Restart environment
make restart
```

**Solution 2: Kill specific port processes**
```bash
# Find and kill process on port 4000
lsof -ti:4000 | xargs kill -9

# Find and kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Find and kill process on port 5432
lsof -ti:5432 | xargs kill -9
```

**Solution 3: Change ports in `.env` file**
```bash
# Edit .env and change ports
API_PORT=4001
FRONTEND_PORT=3001

# Rebuild and restart
make restart
```

---

### Error: Docker Daemon Not Running

**Symptom:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
Error response from daemon: dial unix docker.raw.sock: connect: connection refused
```

**Cause:**
Docker Desktop is not running or not fully started.

**Solution:**
1. Open Docker Desktop application
2. Wait for Docker to fully start (check menu bar icon)
3. Verify Docker is running:
   ```bash
   docker ps
   ```
4. Retry your command:
   ```bash
   make dev
   ```

**macOS Specific:**
- Check "System Preferences → Security & Privacy" for Docker permissions
- Restart Docker Desktop if icon shows error

---

### Error: Minikube Not Started

**Symptom:**
```
Unable to connect to the server: dial tcp [::1]:8080: connect: connection refused
Error: no such host: wander-dev
```

**Cause:**
Minikube cluster is not running.

**Solution:**
```bash
# Start Minikube
minikube start --memory=4096 --cpus=2

# Verify it's running
minikube status

# Configure Docker environment
eval $(minikube docker-env)

# Retry
make dev
```

**If Minikube won't start:**
```bash
# Delete and recreate cluster
minikube delete
minikube start --memory=4096 --cpus=2
eval $(minikube docker-env)
make build
make dev
```

---

### Error: Image Not Found / ImagePullBackOff

**Symptom:**
```
Failed to pull image "wander-api:latest": rpc error: code = Unknown desc = Error response from daemon: pull access denied
```

```bash
kubectl get pods -n wander-dev
NAME                        READY   STATUS             RESTARTS   AGE
api-xxxxx                   0/1     ImagePullBackOff   0          2m
```

**Cause:**
Docker images were not built in Minikube's Docker environment.

**Solution:**
```bash
# Point to Minikube's Docker daemon (IMPORTANT!)
eval $(minikube docker-env)

# Rebuild all images
make build

# Verify images exist
docker images | grep wander

# Restart deployments
kubectl rollout restart deployment -n wander-dev api
kubectl rollout restart deployment -n wander-dev frontend
```

**Persistent Issues:**
```bash
# Delete and rebuild everything
make teardown
eval $(minikube docker-env)
make build
make dev
```

---

### Error: Pods Stuck in Pending

**Symptom:**
```bash
kubectl get pods -n wander-dev
NAME                        READY   STATUS    RESTARTS   AGE
api-xxxxx                   0/1     Pending   0          5m
```

**Cause:**
Insufficient resources in Minikube cluster.

**Solution 1: Check resource availability**
```bash
# Check node resources
kubectl top nodes

# Check pod resource requests
kubectl describe pod -n wander-dev api-xxxxx | grep -A 5 "Requests:"
```

**Solution 2: Increase Minikube resources**
```bash
# Stop Minikube
minikube stop

# Delete and recreate with more resources
minikube delete
minikube start --memory=8192 --cpus=4

# Rebuild and restart
eval $(minikube docker-env)
make build
make dev
```

**Solution 3: Reduce resource requests**

Edit `infra/k8s/*.yaml` to lower resource requests:
```yaml
resources:
  requests:
    cpu: 50m      # Reduced from 100m
    memory: 128Mi # Reduced from 256Mi
```

---

### Error: CrashLoopBackOff

**Symptom:**
```bash
kubectl get pods -n wander-dev
NAME                        READY   STATUS             RESTARTS   AGE
api-xxxxx                   0/1     CrashLoopBackOff   5          3m
```

**Cause:**
Application is crashing immediately after starting.

**Solution:**

**Step 1: Check logs**
```bash
# View current logs
kubectl logs -n wander-dev api-xxxxx

# View logs from previous crash
kubectl logs -n wander-dev api-xxxxx --previous
```

**Step 2: Common causes**

**Database Connection Error:**
```
Error: connect ECONNREFUSED postgres:5432
```
- Check if PostgreSQL is running:
  ```bash
  kubectl get pods -n wander-dev | grep postgres
  ```
- Verify database credentials in ConfigMap:
  ```bash
  kubectl get configmap wander-config -n wander-dev -o yaml
  ```

**Missing Dependencies:**
```
Error: Cannot find module 'express'
```
- Rebuild Docker image with dependencies:
  ```bash
  eval $(minikube docker-env)
  make build
  kubectl rollout restart deployment -n wander-dev api
  ```

**Syntax Error:**
```
SyntaxError: Unexpected token
```
- Fix code error and rebuild image

---

### Error: Service Unavailable (503)

**Symptom:**
```bash
curl http://localhost:4000/health/ready
{"status":"error","services":{"db":"disconnected","redis":"connected"}}
```

**Cause:**
API cannot connect to one or more dependencies.

**Solution:**

**Database Connection Issues:**
```bash
# Check PostgreSQL is running
kubectl get pods -n wander-dev | grep postgres

# Check PostgreSQL logs
make logs-postgres

# Test database connection
kubectl exec -n wander-dev postgres-xxxxx -- psql -U postgres -d wander_dev -c "SELECT 1;"

# Verify service DNS
kubectl get service postgres -n wander-dev
```

**Redis Connection Issues:**
```bash
# Check Redis is running
kubectl get pods -n wander-dev | grep redis

# Check Redis logs
make logs-redis

# Test Redis connection
kubectl exec -n wander-dev redis-xxxxx -- redis-cli ping
```

**If services are down:**
```bash
# Restart all deployments
kubectl rollout restart deployment -n wander-dev postgres
kubectl rollout restart deployment -n wander-dev redis
kubectl rollout restart deployment -n wander-dev api

# Wait for services to be ready
./scripts/wait-for-services.sh
```

---

### Error: Database Seed Failures

**Symptom:**
```
PostgreSQL is running but has no tables
Integration tests fail with "relation 'users' does not exist"
```

**Cause:**
Seed script didn't run or failed silently.

**Solution:**

**Step 1: Check if seed ran**
```bash
# Connect to database
make db-shell

# Check for tables
\dt

# Count records
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM teams;
SELECT COUNT(*) FROM projects;

# Exit
\q
```

**Step 2: Manually re-seed**
```bash
make seed-db
```

**Step 3: Validate seed data**
```bash
./scripts/validate-seed.sh
```

**Step 4: Check seed script logs**
```bash
kubectl logs -n wander-dev postgres-xxxxx | grep "seed"
```

**If seed script has errors:**
1. Fix the SQL syntax in `db/init/seed.sql`
2. Delete and recreate PostgreSQL:
   ```bash
   kubectl delete pod -n wander-dev postgres-xxxxx
   # Wait for pod to restart
   kubectl wait --for=condition=ready pod -l app=postgres -n wander-dev --timeout=60s
   ```

---

### Error: Frontend Shows Blank Page

**Symptom:**
- Browser shows blank page at http://localhost:3000
- No errors in browser console
- Or "Cannot GET /projects" on refresh

**Cause:**
SPA routing not configured properly or frontend not built.

**Solution:**

**Step 1: Check frontend logs**
```bash
make logs-frontend
```

**Step 2: Verify frontend is serving files**
```bash
# Check if frontend pod is running
kubectl get pods -n wander-dev | grep frontend

# Test direct access
curl http://localhost:3000
```

**Step 3: Rebuild frontend**
```bash
eval $(minikube docker-env)

# Navigate to frontend
cd services/frontend

# Install dependencies
npm install

# Build frontend
npm run build

# Rebuild Docker image
cd ../..
docker build -t wander-frontend:latest -f services/frontend/Dockerfile .

# Restart frontend
kubectl rollout restart deployment -n wander-dev frontend
```

**Step 4: Check browser console**
- Open Developer Tools (F12)
- Check Console tab for errors
- Check Network tab for failed requests

**Common Issues:**
- **CORS errors**: API not allowing frontend origin
- **404 on API**: Check `VITE_API_URL` in frontend `.env`
- **White screen**: JavaScript error, check console

---

### Error: Network Policy Blocking Connections

**Symptom:**
- Services can't communicate
- Connection timeout errors
- `curl` from pod to pod fails

**Cause:**
Network policies or DNS issues.

**Solution:**

**Test DNS resolution:**
```bash
# Run debug pod
kubectl run -it --rm debug --image=busybox --restart=Never --namespace=wander-dev -- sh

# Inside pod, test DNS
nslookup postgres
nslookup api

# Test TCP connection
telnet postgres 5432
telnet api 4000

# Exit
exit
```

**Check NetworkPolicies:**
```bash
kubectl get networkpolicies -n wander-dev
```

**If no network policies, check firewall rules:**
- Disable VPN
- Disable local firewall temporarily
- Check corporate firewall settings

---

### Error: Kubectl Command Hangs

**Symptom:**
```bash
kubectl get pods -n wander-dev
# ... hangs forever ...
```

**Cause:**
Lost connection to Kubernetes API server.

**Solution:**
```bash
# Check Minikube status
minikube status

# If stopped, start it
minikube start

# If started but unresponsive, restart
minikube stop
minikube start

# Verify kubectl can connect
kubectl cluster-info
```

---

### Error: Out of Disk Space

**Symptom:**
```
Error: no space left on device
Cannot create container: disk quota exceeded
```

**Cause:**
Docker images, volumes, or logs consuming too much space.

**Solution:**

**Clean up Docker:**
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove build cache
docker builder prune

# Nuclear option: Clean everything
docker system prune -a --volumes
```

**Clean up Minikube:**
```bash
# Delete Minikube cluster
minikube delete

# Restart with fresh cluster
minikube start --memory=4096 --cpus=2
```

---

### Error: Integration Tests Failing

**Symptom:**
```bash
make test
# Tests fail with connection errors or unexpected data
```

**Cause:**
Services not running or seed data incorrect.

**Solution:**

**Step 1: Ensure environment is running**
```bash
# Start environment
make dev

# Wait for all services to be ready
./scripts/wait-for-services.sh

# Verify health
curl http://localhost:4000/health/ready
```

**Step 2: Validate seed data**
```bash
./scripts/validate-seed.sh
```

**Step 3: Run single test**
```bash
# Run specific test to isolate issue
npm test -- --testNamePattern="GET /health returns ok"
```

**Step 4: Check test output**
```bash
# Run tests with verbose output
npm test -- --verbose
```

---

### Error: Cannot Exec into Pod

**Symptom:**
```bash
kubectl exec -it -n wander-dev api-xxxxx -- /bin/sh
error: unable to upgrade connection: container not found
```

**Cause:**
Pod is not running or container crashed.

**Solution:**
```bash
# Check pod status
kubectl get pods -n wander-dev

# If pod is not running, check why
kubectl describe pod -n wander-dev api-xxxxx

# Check logs
kubectl logs -n wander-dev api-xxxxx

# Try bash instead of sh
kubectl exec -it -n wander-dev api-xxxxx -- /bin/bash
```

---

### Error: Permission Denied

**Symptom:**
```bash
./scripts/preflight-check.sh
-bash: ./scripts/preflight-check.sh: Permission denied
```

**Cause:**
Script is not executable.

**Solution:**
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Retry
./scripts/preflight-check.sh
```

---

## Investigation Steps

When encountering an unknown error, follow these steps:

### 1. Check Pod Status
```bash
kubectl get pods -n wander-dev
```

Look for:
- `Running`: Pod is healthy
- `Pending`: Waiting for resources
- `CrashLoopBackOff`: Application crashing
- `ImagePullBackOff`: Image not found
- `Error`: Failed to start

### 2. Describe Pod
```bash
kubectl describe pod -n wander-dev <pod-name>
```

Check:
- **Events**: Recent actions and errors
- **Conditions**: Ready, Initialized, etc.
- **Resource requests**: CPU/memory issues

### 3. View Logs
```bash
# Current logs
kubectl logs -n wander-dev <pod-name>

# Previous logs (if restarted)
kubectl logs -n wander-dev <pod-name> --previous

# Follow logs
kubectl logs -n wander-dev <pod-name> -f
```

### 4. Check Services
```bash
# List services
kubectl get services -n wander-dev

# Check endpoints
kubectl get endpoints -n wander-dev <service-name>
```

### 5. Test Connectivity
```bash
# From your machine
curl http://localhost:4000/health

# From inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never --namespace=wander-dev -- curl api:4000/health
```

## Getting Help

If you're still stuck:

1. **Gather information:**
   ```bash
   # Save all logs
   make logs > debug.log
   
   # Save pod status
   kubectl get pods -n wander-dev > pods.txt
   
   # Describe all resources
   kubectl describe all -n wander-dev > resources.txt
   ```

2. **Search for similar issues:**
   - Check GitHub issues
   - Search Stack Overflow
   - Review Kubernetes documentation

3. **Ask for help with context:**
   - What were you trying to do?
   - What command did you run?
   - What error did you see?
   - What does `kubectl get pods -n wander-dev` show?
   - What do the logs show?

## Prevention Tips

### Regular Maintenance

```bash
# Weekly cleanup
docker system prune
minikube delete && minikube start

# Keep Minikube updated
brew upgrade minikube  # macOS
```

### Before Making Changes

```bash
# Always check current state
make status

# Ensure clean start
make teardown
make dev
```

### After Pulling Updates

```bash
# Rebuild images
eval $(minikube docker-env)
make build
make restart
```

## Useful Debug Commands

### Quick Status Check
```bash
# All-in-one status
kubectl get all -n wander-dev
```

### Resource Usage
```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n wander-dev
```

### Event History
```bash
# Recent events
kubectl get events -n wander-dev --sort-by='.lastTimestamp' | tail -20
```

### DNS Testing
```bash
# Test DNS from debug pod
kubectl run -it --rm debug --image=busybox --restart=Never --namespace=wander-dev -- nslookup postgres
```

### Port Testing
```bash
# Test if port is open
kubectl run -it --rm debug --image=busybox --restart=Never --namespace=wander-dev -- telnet postgres 5432
```

## Related Documentation

- [Setup Guide](./SETUP.md) - Initial setup instructions
- [Architecture](./ARCHITECTURE.md) - System design and components
- [Kubernetes Guide](./KUBERNETES.md) - K8s concepts and commands
- [Database Guide](./DATABASE.md) - Database troubleshooting
- [API Reference](./API.md) - API endpoint testing


# Wander - Setup Guide

This guide walks you through setting up the Wander development environment from scratch.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Tools

| Tool | Version | Installation Link |
|------|---------|------------------|
| **Node.js** | 20.x | [nodejs.org](https://nodejs.org/) |
| **npm** | 10.x+ | Comes with Node.js |
| **Docker Desktop** | Latest | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop) |
| **kubectl** | Latest | [kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/) |
| **Minikube** | Latest | [minikube.sigs.k8s.io/docs/start/](https://minikube.sigs.k8s.io/docs/start/) |
| **Helm** (optional) | Latest | [helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/) |

### Additional Requirements

- **gettext** (for `envsubst` command)
  - macOS: `brew install gettext && brew link --force gettext`
  - Linux: `sudo apt-get install gettext` (Debian/Ubuntu)
- **Git** for version control
- **VS Code** (recommended) with extensions for TypeScript and ESLint

## Step-by-Step Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd wander_devsetup
```

### 2. Install Prerequisites

**macOS Users (Recommended):**

Use the automated installation script:

```bash
make install-prereqs
```

This will install:
- kubectl (Kubernetes command-line tool)
- minikube (Local Kubernetes cluster)
- Prompt you to install Docker Desktop if not present

**Manual Installation:**

If you prefer manual installation or are on Linux/Windows:

**macOS:**
```bash
brew install kubectl minikube
brew install --cask docker
```

**Linux (Ubuntu/Debian):**
```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Docker
sudo apt-get update
sudo apt-get install docker.io
```

**Windows WSL2:**
- Install Docker Desktop for Windows with WSL2 integration
- Install kubectl: `choco install kubernetes-cli`
- Install minikube: `choco install minikube`

### 3. Verify Prerequisites

Run the validation script to ensure all required tools are installed:

```bash
make validate
```

Or run the preflight check:
```bash
./scripts/preflight-check.sh
```

The script will check for:
- kubectl
- docker
- envsubst
- helm
- minikube
- npm
- node

If any tools are missing, install them before proceeding.

### 4. Start Docker Desktop

**Important:** Make sure Docker Desktop is running before proceeding.

- **macOS/Windows:** Open Docker Desktop from Applications
- **Linux:** Ensure Docker daemon is running: `sudo systemctl start docker`

Wait for Docker to be fully started (the whale icon in the menu bar should be steady, not animated).

Verify Docker is running:
```bash
docker ps
```

### 5. Start Minikube

Ensure your local Kubernetes cluster is running:

```bash
minikube start --memory=4096 --cpus=2
```

Verify it's running:

```bash
minikube status
```

### 6. Configure Docker Environment

Point your shell to Minikube's Docker daemon to build images directly in the cluster:

```bash
eval $(minikube docker-env)
```

**Note:** You'll need to run this command in each new terminal session, or add it to your shell profile.

### 7. Install Dependencies

Install all npm dependencies for the monorepo:

```bash
npm install
```

This will install dependencies for:
- Root workspace
- `packages/shared`
- `services/api`
- `services/frontend`

### 8. Set Up Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Review and modify `.env` as needed. Default values work for local development.

### 9. Build Docker Images

Build all service images:

```bash
make build
```

This creates:
- `wander-postgres:latest`
- `wander-api:latest`
- `wander-frontend:latest`
- `redis:7-alpine` (pulled from Docker Hub)

### 10. Start the Development Environment

Launch all services with a single command:

```bash
make dev
```

This will:
1. Run preflight checks
2. Prepare Kubernetes manifests
3. Create the `wander-dev` namespace
4. Apply all Kubernetes resources
5. Wait for services to be ready
6. Set up port forwarding

### 9. Verify the Installation

Once `make dev` completes, verify each service:

**API Health Check:**
```bash
curl http://localhost:4000/health
# Expected: {"status":"ok"}
```

**API Ready Check:**
```bash
curl http://localhost:4000/health/ready
# Expected: {"status":"ok","services":{"db":"connected","redis":"connected"}}
```

**Frontend:**
Open http://localhost:3000 in your browser. You should see the Wander dashboard.

**Database:**
```bash
make db-shell
# Then in psql:
\dt  # List tables
SELECT COUNT(*) FROM users;  # Should return 5
\q   # Exit
```

### 12. Run Integration Tests

Verify everything works end-to-end:

```bash
make test
```

All tests should pass.

## Common First-Run Issues

### Issue: Prerequisites Not Installed

**Symptom:** `make validate` fails with missing kubectl, docker, or minikube

**Solution:**
```bash
# macOS - Use automated script
make install-prereqs

# Or manually
brew install kubectl minikube
brew install --cask docker

# After installing Docker Desktop, open it from Applications
# Wait for it to fully start before proceeding
```

### Issue: Port Already in Use

**Symptom:** `make dev` fails with "port already allocated"

**Solution:**
```bash
# Find and kill processes using the ports
lsof -ti:4000 | xargs kill -9  # API
lsof -ti:3000 | xargs kill -9  # Frontend
lsof -ti:5432 | xargs kill -9  # PostgreSQL

# Or stop any existing port forwards
pkill -f "kubectl port-forward"
```

### Issue: Docker Daemon Not Running

**Symptom:** `Cannot connect to the Docker daemon`

**Solution:**
1. Start Docker Desktop
2. Wait for Docker to fully start (check menu bar icon)
3. Retry `make dev`

### Issue: Minikube Not Started

**Symptom:** `Unable to connect to the server`

**Solution:**
```bash
minikube start
eval $(minikube docker-env)
make dev
```

### Issue: Images Not Found

**Symptom:** Pods stuck in `ImagePullBackOff` or `ErrImagePull`

**Solution:**
```bash
# Ensure you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild images
make build

# Check images are available
docker images | grep wander
```

### Issue: Pods Not Starting

**Symptom:** Pods stuck in `Pending` or `CrashLoopBackOff`

**Solution:**
```bash
# Check pod status
make status

# View pod logs
make logs-api
make logs-postgres

# Describe pod for events
kubectl describe pod -n wander-dev <pod-name>
```

### Issue: Database Seed Failures

**Symptom:** API can't connect to database or no seed data

**Solution:**
```bash
# Manually re-seed the database
make seed-db

# Validate seed data
./scripts/validate-seed.sh
```

## Next Steps

Once your environment is running:

1. **Explore the API**: See [docs/API.md](./API.md) for endpoint documentation
2. **Understand the Architecture**: Read [docs/ARCHITECTURE.md](./ARCHITECTURE.md)
3. **Make Changes**: See [docs/CONTRIBUTING.md](./CONTRIBUTING.md) for development workflow
4. **Troubleshooting**: Check [docs/TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues

## Quick Reference

```bash
make dev          # Start everything
make restart      # Stop and restart everything
make teardown     # Stop and clean up
make status       # Check pod status
make logs-api     # View API logs
make test         # Run integration tests
```

## Development Workflow

After initial setup, your typical workflow will be:

1. Make code changes
2. Rebuild relevant Docker images: `make build`
3. Restart services: `make restart`
4. Test your changes: `make test`
5. View logs if needed: `make logs-api` or `make logs-frontend`

For more details, see [docs/CONTRIBUTING.md](./CONTRIBUTING.md).


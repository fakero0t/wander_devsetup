# Wander

A modern, cloud-native project management application built with React, Node.js, PostgreSQL, and Kubernetes.

## Overview

Wander is a full-stack application demonstrating modern development practices with microservices architecture, containerization, and Kubernetes orchestration. It provides a complete project management system with teams, projects, tasks, and activity tracking.

**Key Features:**
- 🚀 Modern React frontend with Vite and Tailwind CSS
- 🔧 RESTful API with Node.js (to be implemented)
- 🗄️ PostgreSQL database with seed data
- 📦 Docker containerization
- ☸️ Kubernetes deployment on Minikube
- 🧪 Integration testing with Jest
- 📝 Comprehensive documentation

## Quick Start

Get up and running in minutes:

```bash
# 0. Install prerequisites (if not already installed)
make install-prereqs  # macOS only - installs kubectl, minikube

# 1. Install dependencies
npm install

# 2. Start Minikube
minikube start --memory=4096 --cpus=2

# 3. Configure Docker for Minikube
eval $(minikube docker-env)

# 4. Build and start everything
make build
make dev
```

**Access Points:**
- **Frontend**: http://localhost:3000
- **API**: http://localhost:4000
- **API Health**: http://localhost:4000/health

**Verify Installation:**
```bash
make test
```

**Detailed setup instructions:** [docs/SETUP.md](docs/SETUP.md)

## Architecture Overview

Wander follows a microservices architecture running on Kubernetes:

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
┌──────▼─────────┐
│   Frontend     │  React + Vite (Port 3000)
└──────┬─────────┘
       │
┌──────▼─────────┐
│      API       │  Node.js + Express (Port 4000)
└────┬─────┬─────┘
     │     │
┌────▼──┐ ┌▼─────┐
│  DB   │ │Redis │  PostgreSQL 14 + Redis 7
└───────┘ └──────┘

All running in Kubernetes (Minikube)
```

**Read more:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Technology Stack

### Frontend
- **React 18** - UI library
- **TypeScript 5** - Type safety
- **Vite 5** - Build tool
- **Tailwind CSS 3** - Styling
- **React Router 6** - Routing

### Backend
- **Node.js 20** - Runtime
- **Express** - Web framework (to be implemented)
- **PostgreSQL 14** - Database
- **Redis 7** - Caching

### DevOps
- **Docker** - Containerization
- **Kubernetes** - Orchestration
- **Minikube** - Local K8s cluster
- **Jest** - Testing
- **Make** - Automation

### Monorepo
- **npm Workspaces** - Package management
- **TypeScript** - Shared types
- **ESLint** - Code linting

## Command Reference

### Setup Commands

| Command | Description |
|---------|-------------|
| `make install-prereqs` | Install prerequisites (macOS only) |
| `make validate` | Validate system setup |

### Development Commands

| Command | Description |
|---------|-------------|
| `make dev` | Start entire development environment |
| `make build` | Build all Docker images |
| `make restart` | Stop and restart all services |
| `make teardown` | Stop and clean up everything |
| `make test` | Run integration tests |

### Monitoring Commands

| Command | Description |
|---------|-------------|
| `make status` | Check pod status |
| `make logs` | View all logs |
| `make logs-api` | View API logs |
| `make logs-frontend` | View frontend logs |
| `make logs-postgres` | View database logs |
| `make logs-redis` | View Redis logs |

### Database Commands

| Command | Description |
|---------|-------------|
| `make db-shell` | Open PostgreSQL shell |
| `make seed-db` | Re-seed database |

### Utility Commands

| Command | Description |
|---------|-------------|
| `make shell-api` | Shell into API pod |
| `make help` | Show all available commands |

## Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **Frontend** | http://localhost:3000 | React application UI |
| **API** | http://localhost:4000 | REST API endpoints |
| **Health Check** | http://localhost:4000/health | Basic health check |
| **Ready Check** | http://localhost:4000/health/ready | Service readiness |
| **Database** | localhost:5432 | PostgreSQL (via port-forward) |

**Internal Kubernetes Services:**
- `postgres.wander-dev.svc.cluster.local:5432`
- `redis.wander-dev.svc.cluster.local:6379`
- `api.wander-dev.svc.cluster.local:4000`
- `frontend.wander-dev.svc.cluster.local:3000`

## Project Structure

```
wander_devsetup/
├── packages/
│   └── shared/              # Shared TypeScript types
│       ├── src/types/       # User, Team, Project, Task, Activity
│       └── src/constants/   # Enum values
├── services/
│   ├── api/                 # Backend API (to be implemented)
│   │   ├── src/
│   │   └── Dockerfile
│   └── frontend/            # React frontend
│       ├── src/
│       │   ├── components/  # Reusable components
│       │   ├── pages/       # Page components
│       │   └── api/         # API client
│       └── Dockerfile
├── db/
│   ├── init/seed.sql        # Database seed script
│   └── Dockerfile
├── infra/
│   ├── k8s/                 # Kubernetes manifests
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── postgres.yaml
│   │   ├── redis.yaml
│   │   ├── api.yaml
│   │   └── frontend.yaml
│   └── generated/           # Generated manifests (gitignored)
├── scripts/                 # Automation scripts
│   ├── preflight-check.sh
│   ├── wait-for-services.sh
│   ├── prepare-manifests.sh
│   └── validate-seed.sh
├── tests/
│   └── integration.test.ts  # Integration tests
├── docs/                    # Comprehensive documentation
│   ├── SETUP.md
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── DATABASE.md
│   ├── KUBERNETES.md
│   ├── TROUBLESHOOTING.md
│   └── CONTRIBUTING.md
├── Makefile                 # Build automation
├── package.json             # Root workspace
└── README.md               # This file
```

## Documentation

### Getting Started
- **[Setup Guide](docs/SETUP.md)** - Complete installation and setup instructions
- **[Quick Start](#quick-start)** - Get running in 5 minutes

### Understanding the System
- **[Architecture](docs/ARCHITECTURE.md)** - System design, components, and data flow
- **[Database Schema](docs/DATABASE.md)** - Tables, relationships, and queries
- **[Kubernetes Guide](docs/KUBERNETES.md)** - K8s concepts for developers

### Development
- **[API Reference](docs/API.md)** - Complete API endpoint documentation
- **[Contributing](docs/CONTRIBUTING.md)** - Development workflow and guidelines
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## Database Schema

Wander uses PostgreSQL with the following entities:

- **users** - User accounts
- **teams** - Team organizations
- **team_members** - Team membership (junction table)
- **projects** - Projects owned by teams
- **tasks** - Tasks belonging to projects
- **activities** - Activity log / audit trail

**Seed Data:**
- 5 users (alice@wander.com, bob@wander.com, etc.)
- 2 teams (Engineering, Product)
- 2 projects (Website Redesign, Mobile App)
- 6 tasks with various statuses
- 10 recent activities

**Learn more:** [docs/DATABASE.md](docs/DATABASE.md)

## API Endpoints

### Health Checks
- `GET /health` - Basic health check
- `GET /health/ready` - Readiness check (DB + Redis)

### Resources
- `GET /api/users` - List all users
- `GET /api/users/:id` - Get specific user
- `GET /api/teams` - List all teams
- `GET /api/teams/:id` - Get specific team
- `GET /api/teams/:id/members` - Get team members
- `GET /api/projects` - List all projects
- `GET /api/projects/:id` - Get specific project
- `GET /api/projects/:id/tasks` - Get project tasks
- `GET /api/tasks` - List all tasks
- `GET /api/tasks/:id` - Get specific task
- `GET /api/activities` - List recent activities

All endpoints support pagination with `?limit=N&offset=M` query parameters.

**Full API documentation:** [docs/API.md](docs/API.md)

## Development Workflow

### Making Changes

1. **Edit code** in your IDE (VS Code recommended)
2. **Rebuild images** if you changed Docker files:
   ```bash
   eval $(minikube docker-env)
   make build
   ```
3. **Restart services:**
   ```bash
   make restart
   ```
4. **Test changes:**
   ```bash
   make test
   ```
5. **View logs if needed:**
   ```bash
   make logs-api
   ```

### Common Tasks

**Add new API endpoint:**
- Update `services/api/src/` (when implemented)
- Rebuild: `make build`
- Test: `curl http://localhost:4000/api/new-endpoint`

**Update frontend:**
- Edit `services/frontend/src/`
- Rebuild: `make build`
- Check: http://localhost:3000

**Modify database:**
- Edit `db/init/seed.sql`
- Restart: `kubectl delete pod -n wander-dev postgres-xxxxx`

**Read more:** [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

## Testing

### Integration Tests

Wander includes comprehensive integration tests:

```bash
# Run all tests
make test

# Run specific test
npm test -- --testNamePattern="health"

# Run with coverage
npm test -- --coverage
```

**Test Coverage:**
- Health check endpoints
- All CRUD endpoints
- Pagination
- Error handling
- Database connectivity

Tests run against the live development environment with seed data.

## Troubleshooting

### Common Issues

**Port already in use:**
```bash
pkill -f "kubectl port-forward"
make restart
```

**Docker not running:**
```bash
# Start Docker Desktop and retry
make dev
```

**Images not found:**
```bash
eval $(minikube docker-env)
make build
make restart
```

**Database empty:**
```bash
make seed-db
```

**Full troubleshooting guide:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Environment Variables

Key environment variables (see `.env.example`):

```bash
# Database
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=wander_dev
DATABASE_USER=postgres
DATABASE_PASSWORD=dev_password

# API
API_HOST=0.0.0.0
API_PORT=4000

# Frontend
FRONTEND_HOST=0.0.0.0
FRONTEND_PORT=3000
VITE_API_URL=http://localhost:4000

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
```

## Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|--------------|
| Node.js | 20.x | [nodejs.org](https://nodejs.org/) |
| npm | 10.x+ | Comes with Node.js |
| Docker Desktop | Latest | [docker.com](https://www.docker.com/products/docker-desktop) |
| kubectl | Latest | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| Minikube | Latest | [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/) |
| gettext | - | `brew install gettext` (macOS) |

**Verification:**
```bash
./scripts/preflight-check.sh
```

## Contributing

We welcome contributions! Please follow these guidelines:

1. **Code Style:** Follow ESLint rules, use TypeScript
2. **Commits:** Clear, descriptive commit messages
3. **Testing:** Ensure all tests pass before committing
4. **Documentation:** Update docs when adding features

**Read the full guide:** [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

## Security Note

⚠️ **This is a development environment with intentionally relaxed security:**

- Hardcoded passwords in configuration
- No authentication or authorization
- Debug ports exposed
- ConfigMap instead of Secrets

**For production:** Implement authentication, use Secrets, enable TLS, add rate limiting, and follow security best practices.

## Resource Requirements

**Minimum:**
- 2 CPU cores
- 4GB RAM
- 10GB disk space

**Recommended:**
- 4 CPU cores
- 8GB RAM
- 20GB disk space

**Minikube default:**
```bash
minikube start --memory=4096 --cpus=2
```

## Learning Resources

New to the technologies used in Wander?

- **Kubernetes:** [kubernetes.io/docs/tutorials/](https://kubernetes.io/docs/tutorials/)
- **React:** [react.dev/learn](https://react.dev/learn)
- **Docker:** [docs.docker.com/get-started/](https://docs.docker.com/get-started/)
- **TypeScript:** [typescriptlang.org/docs/](https://www.typescriptlang.org/docs/)
- **PostgreSQL:** [postgresql.org/docs/](https://www.postgresql.org/docs/)

## Roadmap

Future enhancements:

- [ ] Complete API implementation with Express
- [ ] User authentication and authorization
- [ ] WebSocket support for real-time updates
- [ ] Advanced task filtering and search
- [ ] File attachments for tasks
- [ ] Email notifications
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Production deployment guides (AWS EKS, GKE, AKS)
- [ ] Monitoring with Prometheus and Grafana
- [ ] API rate limiting

## License

Proprietary - Wander Organization

## Support

For issues, questions, or contributions:

- **Documentation:** [docs/](docs/)
- **Troubleshooting:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **Issues:** GitHub Issues (if available)

---

**Built with ❤️ using modern cloud-native technologies.**

# Wander - Architecture Documentation

This document provides an overview of the Wander system architecture, design decisions, and technology stack.

## System Overview

Wander is a full-stack project management application built as a microservices-based system running on Kubernetes. The architecture follows modern cloud-native patterns with clear separation of concerns.

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    http://localhost:3000
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      Frontend Service                           │
│                    (React + Vite + SPA)                         │
│                   Port: 3000 (exposed)                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    API calls (fetch)
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                        API Service                              │
│                   (Node.js + Express)                           │
│                   Port: 4000 (exposed)                          │
└──────────┬──────────────────────────────────┬───────────────────┘
           │                                  │
           │ SQL Queries                      │ Cache/Session
           │                                  │
┌──────────▼──────────────┐        ┌─────────▼─────────────┐
│   PostgreSQL Database   │        │    Redis Cache        │
│   Port: 5432 (internal) │        │ Port: 6379 (internal) │
│   - Users               │        │ - Sessions            │
│   - Teams               │        │ - Rate limiting       │
│   - Projects            │        │                       │
│   - Tasks               │        │                       │
│   - Activities          │        │                       │
└─────────────────────────┘        └───────────────────────┘

                    All running in
              ┌─────────────────────────┐
              │  Kubernetes Cluster     │
              │  (Minikube for dev)     │
              │  Namespace: wander-dev  │
              └─────────────────────────┘
```

## Service Communication Flows

### 1. Frontend → API Flow

```
User Action (Dashboard Page Load)
    ↓
React Component (Dashboard.tsx)
    ↓
API Client (apiGet)
    ↓
HTTP GET /api/activities
    ↓
API Service (Express Router)
    ↓
Database Query (PostgreSQL)
    ↓
JSON Response
    ↓
React State Update
    ↓
UI Render
```

### 2. API → Database Flow

```
HTTP Request
    ↓
Express Middleware
    ↓
Route Handler
    ↓
Database Pool (pg)
    ↓
SQL Query Execution
    ↓
Result Parsing
    ↓
JSON Response
```

### 3. Health Check Flow

```
Kubernetes Readiness Probe
    ↓
HTTP GET /health/ready
    ↓
API Health Check Handler
    ↓
┌───────────────────────────┐
│ 1. Test DB Connection     │
│ 2. Test Redis Connection  │
│ 3. Return Status          │
└───────────────────────────┘
    ↓
200 OK → Pod marked Ready
503 Error → Pod marked Not Ready
```

## Database Schema

### Entity Relationship Diagram

```
┌──────────────┐
│    users     │
│──────────────│
│ id (PK)      │◄──────────────┐
│ name         │                │
│ email (UQ)   │                │
│ created_at   │                │
│ updated_at   │                │
└──────────────┘                │
       ▲                        │
       │                        │
       │                        │
       │                  ┌─────┴──────────┐
       │                  │  team_members  │
       │                  │────────────────│
       │                  │ id (PK)        │
       │                  │ team_id (FK)   │◄──────┐
       │                  │ user_id (FK)   │       │
       │                  │ joined_at      │       │
       │                  └────────────────┘       │
       │                                           │
       │                                           │
       │                  ┌─────────────┐          │
       │                  │    teams    │          │
       │                  │─────────────│          │
       │                  │ id (PK)     │──────────┘
       │                  │ name (UQ)   │
       │                  │ description │
       │                  │ created_at  │
       │                  │ updated_at  │
       │                  └─────────────┘
       │                         ▲
       │                         │
       │                         │
       │                  ┌──────┴───────┐
       │                  │   projects   │
       │                  │──────────────│
       │                  │ id (PK)      │
       │                  │ team_id (FK) │
       │                  │ name         │
       │                  │ description  │
       │                  │ status       │
       │                  │ created_at   │
       │                  │ updated_at   │
       │                  └──────────────┘
       │                         ▲
       │                         │
       │                         │
       │                  ┌──────┴────────┐
       │                  │     tasks     │
       │                  │───────────────│
       │                  │ id (PK)       │
       │                  │ project_id(FK)│
       └──────────────────┤ assigned_to(FK)
                          │ title         │
                          │ description   │
                          │ status        │
                          │ priority      │
                          │ created_at    │
                          │ updated_at    │
                          └───────────────┘

       ┌──────────────┐
       │  activities  │
       │──────────────│
       │ id (PK)      │
       │ user_id (FK) │──────► users.id
       │ action       │
       │ entity_type  │
       │ entity_id    │
       │ description  │
       │ created_at   │
       └──────────────┘
```

### Key Relationships

- **Users ↔ Teams**: Many-to-many through `team_members`
- **Teams → Projects**: One-to-many (team has many projects)
- **Projects → Tasks**: One-to-many (project has many tasks)
- **Users → Tasks**: One-to-many optional (user assigned to tasks)
- **Users → Activities**: One-to-many (user creates activities)

## Kubernetes Architecture

### Namespace: `wander-dev`

All resources are isolated in the `wander-dev` namespace for clean separation.

### Resource Structure

```
wander-dev namespace
│
├── ConfigMap: wander-config
│   └── Environment variables for all services
│
├── Deployment: postgres
│   ├── Container: postgres:14-alpine
│   ├── Volume: seed script (hostPath)
│   ├── Probes: readiness + liveness
│   └── Resources: 100m CPU, 256Mi RAM
│
├── Service: postgres (ClusterIP)
│   └── Port: 5432
│
├── Deployment: redis
│   ├── Container: redis:7-alpine
│   ├── Probes: readiness + liveness
│   └── Resources: 50m CPU, 128Mi RAM
│
├── Service: redis (ClusterIP)
│   └── Port: 6379
│
├── Deployment: api
│   ├── Container: wander-api:latest
│   ├── Probes: HTTP /health/ready + /health
│   ├── Resources: 100m CPU, 256Mi RAM
│   └── Debug Port: 9229 (dev mode)
│
├── Service: api (ClusterIP)
│   └── Port: 4000
│
├── Deployment: frontend
│   ├── Container: wander-frontend:latest
│   ├── Probes: HTTP / (root)
│   └── Resources: 50m CPU, 128Mi RAM
│
└── Service: frontend (ClusterIP)
    └── Port: 3000
```

### Service Discovery

Services communicate using Kubernetes DNS:

- `postgres.wander-dev.svc.cluster.local:5432` → PostgreSQL
- `redis.wander-dev.svc.cluster.local:6379` → Redis
- `api.wander-dev.svc.cluster.local:4000` → API

Short names work within the same namespace:
- `postgres:5432`
- `redis:6379`
- `api:4000`

### Health Probes

**Readiness Probes:**
- Determine when a pod is ready to receive traffic
- Failed probes → pod removed from service endpoints
- Used for: API, Frontend, PostgreSQL, Redis

**Liveness Probes:**
- Determine if a pod is healthy and running
- Failed probes → Kubernetes restarts the pod
- Used for: API, Frontend, PostgreSQL, Redis

Example (API):
```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 4000
  initialDelaySeconds: 20
  periodSeconds: 5
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /health
    port: 4000
  initialDelaySeconds: 25
  periodSeconds: 10
  failureThreshold: 3
```

### Resource Limits

Conservative limits ensure stable operation on developer machines:

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|------------|-----------|----------------|--------------|
| API | 100m | 500m | 256Mi | 512Mi |
| Frontend | 50m | 200m | 128Mi | 256Mi |
| PostgreSQL | 100m | 1000m | 256Mi | 512Mi |
| Redis | 50m | 200m | 128Mi | 256Mi |
| **Total** | **300m** | **1900m** | **768Mi** | **1536Mi** |

**Rationale:**
- Fits within Minikube's default 2 CPU / 4GB RAM
- Prevents resource starvation
- Allows headroom for OS and other processes

## Technology Stack

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| **React** | 18.2 | UI library for component-based architecture |
| **TypeScript** | 5.3 | Type safety and developer experience |
| **Vite** | 5.0 | Fast build tool with HMR |
| **Tailwind CSS** | 3.4 | Utility-first styling framework |
| **React Router DOM** | 6.20 | Client-side routing |

**Rationale:**
- React: Industry standard, large ecosystem
- Vite: Faster than Create React App, better DX
- Tailwind: Rapid prototyping, consistent design
- TypeScript: Catches errors early, better IDE support

### Backend

| Technology | Version | Purpose |
|------------|---------|---------|
| **Node.js** | 20.x | JavaScript runtime |
| **Express** | 4.x | Web framework (to be implemented) |
| **PostgreSQL** | 14 | Relational database |
| **Redis** | 7 | Caching and sessions |
| **pg** | 8.x | PostgreSQL client (to be implemented) |

**Rationale:**
- Node.js: Unifies frontend/backend language
- Express: Minimal, flexible, well-documented
- PostgreSQL: ACID compliance, JSON support, robust
- Redis: Fast in-memory operations

### DevOps

| Technology | Purpose |
|------------|---------|
| **Docker** | Containerization |
| **Kubernetes** | Orchestration |
| **Minikube** | Local K8s cluster |
| **Make** | Build automation |
| **Jest** | Testing framework |
| **ESLint** | Code linting |

### Monorepo Structure

```
wander_devsetup/
├── packages/
│   └── shared/          # Shared TypeScript types
├── services/
│   ├── api/            # Backend service
│   └── frontend/       # React application
├── db/                 # Database initialization
├── infra/
│   ├── k8s/           # Kubernetes manifests (templates)
│   └── generated/     # Generated manifests (gitignored)
├── scripts/           # Automation scripts
├── tests/             # Integration tests
└── docs/              # Documentation
```

**Rationale:**
- **npm workspaces**: Native monorepo support, simpler than Lerna
- **Shared package**: DRY principle, consistent types
- **Separate services**: Clear boundaries, independent deployment

## Design Decisions

### 1. Why Kubernetes for Local Development?

**Decision:** Use Kubernetes (Minikube) locally instead of Docker Compose.

**Rationale:**
- Production parity: Develop in the same environment as production
- Learn K8s concepts early
- Practice with health probes, service discovery, resource limits
- Better for microservices architecture

**Trade-offs:**
- Higher complexity and resource usage
- Steeper learning curve
- Worth it for production-like environment

### 2. Why Monorepo?

**Decision:** Use npm workspaces for monorepo structure.

**Rationale:**
- Share types between frontend and API
- Single `npm install` for all dependencies
- Coordinated versioning
- Easier refactoring across boundaries

### 3. Why TypeScript Everywhere?

**Decision:** Use TypeScript for all JavaScript code.

**Rationale:**
- Type safety catches bugs early
- Better IDE autocomplete and refactoring
- Self-documenting code
- Shared types reduce duplication

### 4. Why Idempotent Seed Scripts?

**Decision:** Make `seed.sql` idempotent with drop/recreate pattern.

**Rationale:**
- Can re-run without errors
- Simplifies development workflow
- Matches production migration patterns
- Easy to reset to known state

### 5. Why Port Forwarding Instead of LoadBalancer?

**Decision:** Use `kubectl port-forward` for local access.

**Rationale:**
- LoadBalancer requires external IP (cloud only)
- NodePort exposes unpredictable ports
- Port forwarding gives predictable localhost URLs
- Simple and secure for development

### 6. Why ConfigMap Instead of Secrets?

**Decision:** Use ConfigMap for all configuration in development.

**Rationale:**
- Faster iteration (no base64 encoding)
- Acceptable for local development
- Production would use Secrets
- Clear separation of concerns

## Security Considerations

**Note:** This is a development environment with intentionally relaxed security.

**Development:**
- Hardcoded passwords in manifests
- No TLS/SSL
- No authentication or authorization
- ConfigMap instead of Secrets
- Debug ports exposed

**Production Changes Needed:**
- Use Kubernetes Secrets for sensitive data
- Implement TLS with cert-manager
- Add authentication (JWT, OAuth)
- Add authorization (RBAC)
- Remove debug ports
- Use private container registry
- Implement network policies
- Add API rate limiting
- Enable audit logging

## Performance Considerations

### Database Indexing

All foreign keys are indexed for fast joins:
- `team_members(team_id)`
- `team_members(user_id)`
- `projects(team_id)`
- `tasks(project_id)`
- `tasks(assigned_to)`
- `activities(user_id)`

### Caching Strategy

Redis is included for:
- Session storage (future)
- API response caching (future)
- Rate limiting (future)

Currently unused but infrastructure ready.

### Resource Efficiency

- Alpine-based images for smaller size
- Multi-stage Docker builds
- Connection pooling for database
- Lazy loading for frontend routes (future)

## Future Enhancements

Potential architectural improvements:

1. **API Gateway**: Add Kong or Nginx for routing, rate limiting
2. **Message Queue**: Add RabbitMQ or Kafka for async operations
3. **Observability**: Add Prometheus + Grafana for metrics
4. **Tracing**: Add Jaeger for distributed tracing
5. **CI/CD**: Add GitHub Actions for automated testing and deployment
6. **CDN**: Add CloudFront or Cloudflare for frontend assets
7. **Load Balancing**: Add multiple replicas with load balancer
8. **Database Replication**: Add read replicas for scaling
9. **Service Mesh**: Add Istio for advanced traffic management
10. **Feature Flags**: Add LaunchDarkly or similar

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [React Documentation](https://react.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Twelve-Factor App](https://12factor.net/)


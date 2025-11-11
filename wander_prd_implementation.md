## 21. Implementation Sensible Defaults Summary

This section documents all technical decisions made with sensible defaults to simplify implementation.

### Quick Decision Reference

| Category | Decision | Details |
|----------|----------|---------|
| **Technology Versions** | Pinned major, flexible minor | Express ^4.18.0, React ^18.2.0, Vite ^5.0.0, Node 20-alpine |
| **Shared Package** | Host-based watch mode | `tsc --watch` runs on host, outputs to `packages/shared/dist/` |
| **Database Migrations** | Knex auto-run on startup | `await knex.migrate.latest()` before Express starts, fails pod on error |
| **Seed Idempotency** | PL/pgSQL DO block | Check user count, skip if > 0, otherwise drop/create/seed |
| **Port Forwarding** | Auto-background in make dev | PIDs saved to `.pids/{service}.pid`, killed on teardown |
| **Frontend API URL** | Localhost via port-forward | `VITE_API_URL=http://localhost:4000`, no Vite proxy |
| **Volume Mounts** | hostPath with ${WORKSPACE_PATH} | envsubst replaces with `$(PWD)`, hostPath type: Directory |
| **Docker Context** | Root (monorepo) | Multi-stage copies workspace files, builds from service dir |
| **Template Processing** | envsubst to generated/ | `infra/k8s/*.yaml` → `infra/generated/*.yaml` (gitignored) |
| **Dev vs Prod YAMLs** | Single base + envsubst | `NODE_ENV` variable switches volume mounts and commands |
| **Namespace** | Hard-coded wander-dev | Not configurable, keeps implementation simple |
| **Redis Caching** | Graceful degradation | If unavailable, log warning and continue without cache |
| **Teardown** | Delete namespace, keep images | Kill port-forwards, clean generated files, remove .pids/ |
| **Environment Loading** | dotenv in dev, K8s in prod | API uses `dotenv/config`, frontend uses Vite built-in |
| **CORS** | Localhost:3000 with credentials | Allow credentials: true, exact origin match |
| **Activity Logging** | Manual creation only | Developer calls helper function on significant actions |
| **Error Responses** | Validation-aware format | Simple: `{message}`, validation: `{message, errors[]}`, dev includes stack |
| **Testing** | Jest on live environment | `make test` assumes `make dev` running, basic smoke tests |
| **Code Quality** | Basic ESLint, no Prettier | Keep simple, no git hooks or pre-commit |
| **Seed Data** | 5 users, 2 teams, 2 projects | 6 tasks, 10 activities, no passwords or roles |
| **Port Conflicts** | Fail with clear message | Preflight checks ports, no auto-reassignment |
| **Status/Priority Values** | Fixed enums | Status: todo/in_progress/done, Priority: low/medium/high |
| **Empty States** | Simple text messages | Centered muted text, no complex UI |
| **Modals** | Custom React Portal | Tailwind styling, no external library |
| **Makefile Additions** | restart + per-service logs | `make restart`, `make logs-{service}` |

### API Layer
- Simple endpoints: GET, POST, PUT, DELETE (CRUD only)
- No bulk operations, filtering, sorting, or complex query params
- Pagination via `limit` and `offset` query params (default: 10)
- Array responses (no wrapper/metadata)
- No custom error middleware (let errors bubble up)
- Error format: `{ message: "..." }`
- HTTP status: 200, 201, 204, 500
- CORS: Allow localhost:3000 only
- Logging: method, path, status, response time to console
- No transactions or advanced DB features
- Connection pooling: 10 connections

### Frontend Layer
- Component-level state (useState only)
- No global state management
- No prop drilling (co-locate data with components)
- Fresh data fetch on page load (no caching)
- Create/edit via modal dialogs
- Links on entity names (project, team names)
- No search, sort, filter UI
- Browser locale for dates/times
- No service workers or offline capability
- Build output: `dist/` folder
- TypeScript: `strict: false`

### Database Layer
- Primary keys: auto-incrementing SERIAL
- Soft deletes: not used (hard delete with cascading)
- Timestamps: UTC, auto-managed
- Indexes on: foreign keys, email, status, created_at
- No composite indexes
- Connection: env vars (HOST, PORT, DB, USER, PASS)
- Fresh data each startup
- Seed script: automatic + idempotent

### Kubernetes Layer
- 1 replica per service (no load balancing needed)
- All services: ClusterIP (internal-only)
- Simple resource names (api, postgres, redis, frontend)
- Resource requests & limits: defined per service
- Readiness probe: `/health/ready` (checks DB + Redis)
- Liveness probe: `/health` (basic check)
- No ingress controller
- Port-forward for host access

### Build & Development
- Dockerfiles: multi-stage (dev + prod via NODE_ENV)
- Hot reload: enabled for both API and frontend
- Component state: preserved across reloads
- TypeScript errors: logged, don't block reload
- Redis: no persistence (ephemeral)
- Makefile: verbose by default
- All additional commands pre-configured

### Dependency Versions
- Express: ^4.18.0 (stable, pinned major version)
- Knex: ^3.0.0 (latest major version)
- React: ^18.2.0 (latest stable)
- React Router: ^6.20.0 (v6 latest)
- Vite: ^5.0.0 (latest major version)
- Tailwind CSS: ^3.4.0 (latest stable)
- TypeScript: ^5.3.0 (modern version)
- Node.js: 20-alpine (Docker base image)
- PostgreSQL: 14-alpine (Docker base image)
- Redis: 7-alpine (Docker base image)

### Shared Package Development
- Compilation: `tsc --watch` in dev mode
- Output: `packages/shared/dist/` (gitignored)
- API and Frontend watch: `packages/shared/dist/` for changes
- Package name: `@wander/shared` (npm workspace)
- Auto-reload: Both services restart when shared types change
- Build command: `npm run build` (runs tsc)

### Database Migrations
- Tool: Knex migrations (`knex migrate:make <name>`)
- Location: `services/api/src/database/migrations/`
- Auto-run: `knex.migrate.latest()` on API startup
- Seed separate: Seed script runs via PostgreSQL init, not Knex
- Migration format: Timestamped filenames (Knex default)

### Port-Forward Automation
- `make dev` sets up port-forwards automatically in background
- PIDs saved to `.pids/` directory (gitignored)
- Ports forwarded: frontend (3000), api (4000), postgres (5432), redis (6379)
- `make teardown` kills all port-forward processes
- Commands: `kubectl port-forward svc/{service} {port}:{port} &`

### Frontend API URL Configuration
- Dev mode: `VITE_API_URL=http://localhost:4000`
- Browser accesses API via port-forward, not internal DNS
- No Vite proxy needed (direct fetch to localhost:4000)
- CORS configured in API to allow localhost:3000 origin

### Docker Volume Mounts (Development)
- API: mount `services/api/src/` to `/app/src/`
- Frontend: mount `services/frontend/src/` to `/app/src/`
- Shared: mount `packages/shared/src/` to `/workspace/packages/shared/src/`
- Excluded: `node_modules` via `.dockerignore` (prevents conflicts)
- K8s implementation: hostPath volumes in development deployment YAMLs
- Note: hostPath works for Docker Desktop Kubernetes (shares host filesystem)

### Docker Build Context (Monorepo)
- Build context: Repository root (for workspace access)
- Dockerfiles: Located in service directories (`services/api/Dockerfile`)
- Multi-stage: Copy root package.json and package-lock.json first
- Workspace install: `npm ci --workspaces` in builder stage
- Service-specific: WORKDIR set to service directory after install

### Template Processing (envsubst)
- Template files: `infra/k8s/*.yaml` (version-controlled)
- Generated files: `infra/generated/*.yaml` (gitignored)
- Process: `envsubst < template.yaml > generated/template.yaml`
- Makefile step: envsubst runs before `kubectl apply`
- Variables: Sourced from `.env` file

### Kubernetes Namespace
- Name: `wander-dev` (hard-coded, not configurable)
- All resources: Deployed to this namespace
- Isolation: Keeps dev environment separate from other workloads
- Cleanup: `kubectl delete namespace wander-dev` removes all resources

### Redis Cache Implementation
- Key format: `cache:{entity}:{id?}` (e.g., `cache:activities:all`)
- Activity feed: `cache:activities:all` (TTL: 3600 seconds)
- User activities: `cache:activities:user:{id}` (TTL: 3600 seconds)
- API responses: `cache:api:{endpoint}` (TTL: 300 seconds)
- Invalidation: Manual on write operations (no auto-invalidation)
- Client: `ioredis` library for Node.js

### Teardown Behavior
- Deletes: All Kubernetes resources in namespace
- Preserves: Docker images (for faster restart)
- Cleans: `infra/generated/*.yaml` files
- Stops: Port-forward background processes (via saved PIDs)
- Removes: `.pids/` directory
- Database: Data wiped (no persistent volumes)

### Logging Format
- Development: Human-readable console output
- Production: Structured JSON (via pino or winston)
- Switch: Based on `NODE_ENV` environment variable
- Format: `[timestamp] level: message { metadata }`
- Colors: Enabled in dev, disabled in prod

### Error Handling Strategy
- Fail fast: Stop on first error, no automatic rollback
- Clear messages: Point to resolution steps
- Manual cleanup: User runs `make teardown` after failure
- Idempotent: `make dev` can be re-run after fixing issues
- Preflight checks: Warn about missing prerequisites

### Testing Framework
- Framework: Jest (Node.js standard)
- Location: `tests/integration.test.ts`
- Command: `make test` (runs jest)
- Target: Live dev environment (assumes `make dev` already running)
- Scope: Basic smoke tests (health checks, CRUD operations)
- Config: `jest.config.js` at repository root

### Initial Setup Automation
- `.env` creation: Auto-copy from `.env.example` if missing
- Preflight checks: Warn about missing tools (Docker, kubectl, envsubst)
- Directory creation: Auto-create `.pids/`, `infra/generated/`
- First run: No special command needed, `make dev` handles everything
- Prerequisites: Documented in README with installation links

### Makefile Implementation Details
- Environment export: Source `.env` file at Makefile start via `include .env` or `export $(shell cat .env)`
- Preflight script: Exit code 0 (success) or 1 (failure), stops make execution on failure
- Background port-forwards: Use `kubectl port-forward ... > /dev/null 2>&1 & echo $! >> .pids/{service}.pid`
- PID capture: One file per service in `.pids/` directory
- Teardown: Read all `.pids/*.pid` files and kill processes: `kill $(cat .pids/*.pid) 2>/dev/null || true`

### Development Volume Mounts (Kubernetes hostPath)
- Workspace path: Use `$(PWD)` in Makefile, substitute into YAML via envsubst as `${WORKSPACE_PATH}`
- hostPath type: `Directory` (must exist before pod starts)
- Cross-platform: Works on Docker Desktop K8s (Mac/Windows) as it auto-shares host filesystem
- Shared package mount: Mounted in both API and Frontend pods at `/workspace/packages/shared/`
- Path structure: `hostPath: { path: "${WORKSPACE_PATH}/services/api/src", type: Directory }`

### Knex Migration Auto-Run
- Execution point: In `services/api/src/index.ts` before starting Express server
- Code: `await knex.migrate.latest()` with try/catch
- On failure: Log error and exit process (exit code 1), pod will restart
- Connection retry: Knex built-in retry (10 attempts, 2s delay between)
- Migrations table: `knex_migrations` (default Knex table)

### Wait-for-Services Script
- Mechanism: `curl -f http://{service}:port/health/ready` via kubectl exec or port-forward
- Approach: Use kubectl for internal checks: `kubectl exec -n wander-dev deploy/{service} -- curl -f localhost:port/health/ready`
- Polling: Parallel checks using background jobs in bash (`check_api & check_frontend & wait`)
- Interval: 5 seconds between checks, max 60 attempts (5 minutes total)
- Output: Progress indicator per service (spinner or dots)

### Shared Package Watch Strategy
- Execution location: Host machine (not in Kubernetes)
- Implementation: `make dev` starts `npm run dev --workspace=packages/shared` in background on host
- PID tracking: Save to `.pids/shared-watch.pid`
- Why host: Simpler than container, faster file system access
- Detection: nodemon/Vite watch `node_modules/@wander/shared/dist/**/*.js` (symlinked by npm workspaces)

### Development vs Production Configuration
- Strategy: Single base YAML with envsubst templating for mode switching
- Environment variable: `NODE_ENV=${NODE_ENV:-development}` (default to development)
- Volume mounts: Conditional via envsubst - if `NODE_ENV=development`, include volumes; if production, omit
- Command override: Use envsubst to set CMD: dev = `npm run dev`, prod = `npm start`
- No Kustomize: Keep it simple with envsubst and environment variables
- Example: `${DEV_VOLUME_MOUNT}` expands to volume YAML block or empty string based on NODE_ENV

### Mock Data Size
- Seed script: Small dataset, ~5KB SQL file
- Execution time: < 2 seconds
- Row counts: 5 users, 2 teams, 2 projects, 6 tasks, 10 activities
- No performance concerns for seed script

### CORS Configuration Details
- Allowed origins: `http://localhost:3000` (exact match only)
- Browser handling: Modern browsers normalize, no need for trailing slash variant
- 127.0.0.1: Not needed (browsers treat localhost specially)
- Credentials: `Access-Control-Allow-Credentials: true` (for future cookie support)
- Headers: `Content-Type, Authorization`
- Methods: `GET, POST, PUT, DELETE, OPTIONS`
- Implementation: `cors` npm package with options object

### Frontend Production Serve Config
- Command: `serve -s dist -l 3000 --no-clipboard`
- Flags: `-s` (SPA mode, fallback to index.html), `-l` (port), `--no-clipboard` (no auto-copy URL)
- CORS: Not needed (serve is just static files, CORS handled by API)
- Environment: Vite bakes `VITE_*` variables into build at build time

### Redis Connection Configuration
- Client: ioredis with options `{ host, port, retryStrategy, maxRetriesPerRequest: 3 }`
- Retry strategy: Exponential backoff, max 3 retries then fail
- Graceful degradation: If Redis unavailable, API logs warning and skips caching (continues operation)
- Implementation: Try/catch around Redis operations, return uncached data on error
- Health check: `/health/ready` marks Redis as "degraded" but returns 200 if DB works

### TypeScript Path Aliases
- Shared package: `@wander/shared` via npm workspace (no path alias needed)
- API: `@/routes/*`, `@/database/*`, `@/cache/*` → maps to `src/routes/*` etc.
- Frontend: `@/pages/*`, `@/components/*`, `@/api/*` → maps to `src/pages/*` etc.
- Configuration: In each `tsconfig.json` under `compilerOptions.paths`
- No `rootDirs` needed (npm workspaces handle shared package)

### Nodemon Configuration (services/api/nodemon.json)
```json
{
  "watch": ["src/**/*.ts", "../../../packages/shared/dist/**/*.js"],
  "ext": "ts,js",
  "ignore": ["src/**/*.test.ts", "node_modules"],
  "exec": "ts-node -r tsconfig-paths/register src/index.ts",
  "env": {
    "NODE_ENV": "development"
  }
}
```

### Environment Variable Loading Strategy
- API: Use `dotenv` package to load `.env` in development
- Load order: 1) Read `.env` file (dotenv), 2) Override with K8s env vars if present
- Kubernetes: Pass env vars via ConfigMap + environment blocks in YAML
- Development: Relies on `.env` file primarily
- Production: Only uses K8s environment variables (no .env file in container)
- Code: `import 'dotenv/config'` at top of `src/index.ts`

### Frontend Environment Variable Loading
- Package: `dotenv` (for Vite compatibility, though Vite has built-in support)
- Vite behavior: Automatically loads `.env` file and exposes `VITE_*` variables
- No explicit dotenv call needed (Vite handles it)
- Build time: Variables baked into bundle during `vite build`
- Runtime: No environment variable access (all compile-time)

### Database Connection Configuration (Knex)
```javascript
{
  client: 'pg',
  connection: {
    host: process.env.DATABASE_HOST,
    port: parseInt(process.env.DATABASE_PORT),
    database: process.env.DATABASE_NAME,
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    ssl: false  // No SSL for local development
  },
  pool: {
    min: 2,
    max: 10
  },
  migrations: {
    directory: './src/database/migrations',
    tableName: 'knex_migrations'
  }
}
```

### Error Response Format
- Success: `{ ...data }` (direct object or array)
- Simple error: `{ message: "Error description" }`
- Validation error: `{ message: "Validation failed", errors: [{ field: "email", message: "Invalid format" }] }`
- Development mode: Include stack trace in additional `stack` field
- Production mode: Generic messages only, no stack traces
- HTTP status: 200 (OK), 201 (Created), 204 (No Content), 400 (Bad Request), 404 (Not Found), 500 (Server Error)

### Activity Log Implementation
- Strategy: Manual creation (not automatic)
- Developer responsibility: Call activity creation in route handlers where needed
- Helper function: `createActivity(userId, action, entityType, entityId, description)`
- Example: After creating task, call `createActivity(req.userId, 'create', 'task', task.id, 'Created new task')`
- Not on every CRUD: Only on significant actions (create task, update status, assign user)
- Cache invalidation: Clear activity cache after creating activity

### Additional Implementation Details

**Example curl commands** (for API.md documentation):
```bash
# List projects
curl http://localhost:4000/api/projects

# Create project
curl -X POST http://localhost:4000/api/projects \
  -H "Content-Type: application/json" \
  -d '{"team_id": 1, "name": "New Project", "description": "Description"}'

# Update task status
curl -X PUT http://localhost:4000/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"status": "done"}'
```

**Database column types**:
- VARCHAR fields: 255 max (name, email, status, priority, action, entity_type)
- TEXT fields: Unlimited (description)
- INTEGER: All IDs and foreign keys
- TIMESTAMP: All date/time fields

**Frontend standards**:
- Functional components only (no class components)
- Hooks: useState, useEffect, useCallback (as needed)
- No favicon.ico specified (browser will show default)
- Props: TypeScript interfaces for all prop types

**Code quality tools**:
- ESLint: Basic config, no strict rules (keep it simple)
- Prettier: Not required (optional)
- Git hooks: Not configured (out of scope)
- Pre-commit checks: None (keep developer flow smooth)

### Seed Data Specification (Canonical)
- **User count**: 5 users (Alice, Bob, Carol, David, Emma)
- **Team count**: 2 teams (Frontend Squad, Backend Brigade)
- **Project count**: 2 projects (Dashboard Redesign, API v2 Migration)
- **Task count**: 6 tasks across both projects
- **Activity count**: 10 sample activity entries
- **User passwords**: None (no password field in schema)
- **Team roles**: None (no role column, all members equal)
- **Mock project naming**: Keep realistic, avoid meta-references

### Port Conflict Handling
- Detection: Preflight script checks if ports 3000, 4000, 5432, 6379 are in use
- Command: `lsof -i :PORT` or `netstat` depending on platform
- Behavior: Fail with clear error message listing occupied ports
- Error message: "❌ Port {port} is already in use. Stop the process or change {SERVICE}_PORT in .env"
- No automatic port reassignment (keep it explicit)

### Data Persistence Strategy
- Default: Always fresh database (no persistence between teardown/dev)
- No toggle option (PERSIST_DATA not supported - keep it simple)
- Rationale: Ensures consistent state, prevents "works on my corrupted data" issues
- For iterative dev: Use `kubectl exec` to manually run SQL or keep environment running

### Schema Evolution During Development
- Approach: Run `make teardown` then `make dev` for new migrations
- No hot-apply of migrations to running DB (avoid state inconsistency)
- Migration testing: Develop migrations locally, test via full restart
- Future enhancement: Could add `make migrate` for applying migrations to running pods

### Authentication Placeholder
- Implementation: No authentication or authorization
- Code comment: Add `// TODO: Add authentication middleware here` in API routes
- Future consideration: JWT tokens, user sessions, role-based access control
- User model: Email field present but no password field

### API Versioning Strategy
- Base path: `/api` (no version number)
- Rationale: Simplicity for demo, versioning adds complexity
- Breaking changes: Not expected in demo application
- Future: Could add `/api/v2` if needed, but not in initial implementation

### Task and Status Values (Canonical)
- **Task priority**: `low`, `medium`, `high` (VARCHAR, default: 'medium')
- **Task status**: `todo`, `in_progress`, `done` (VARCHAR, default: 'todo')
- **Project status**: `planning`, `active`, `completed` (VARCHAR, default: 'active')
- Database constraints: No CHECK constraints (keep flexible for demo)
- Shared types: Export as TypeScript enums in `packages/shared`

### Request Body Limits
- Maximum JSON body size: 10MB
- Express middleware: `express.json({ limit: '10mb' })`
- Rationale: Generous for demo, handles reasonable payloads
- No multipart/form-data support (not needed for demo)

### Rate Limiting
- Implementation: None (not needed for local development)
- Rationale: Adds complexity without value in single-user environment
- Production consideration: Would add in real deployment

### React Router Configuration
- Mode: BrowserRouter (clean URLs without #)
- Server fallback: `serve -s` handles SPA routing automatically
- Routes: `/`, `/teams`, `/projects`, `/projects/:id`, `/users`
- 404 handling: Catch-all route shows "Page not found"

### Date/Time Display Format
- API response: ISO 8601 strings (UTC)
- Frontend display: `new Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeStyle: 'short' }).format(date)`
- Example output: "Nov 11, 2025, 2:30 PM"
- Relative times: Not implemented (keep simple)

### Empty State Handling
- Dashboard (no activities): Show message "No recent activity. Create a task to get started!"
- Project list (no projects): "No projects yet. Create one to begin."
- Task list (no tasks): "No tasks in this project."
- User list: Always has seed data (not empty)
- Styling: Centered text with muted color

### Modal Dialog Implementation
- Library: Custom implementation using React Portal
- Styling: Tailwind CSS with overlay and centered card
- Close: Click outside or X button
- Components: `<Modal>`, `<ModalHeader>`, `<ModalBody>`, `<ModalFooter>`
- No dependency on external modal libraries

### Additional Makefile Commands
- `make restart`: Shortcut for `make teardown && make dev`
- `make logs-api`: Stream logs from API pod only
- `make logs-frontend`: Stream logs from frontend pod only
- `make logs-postgres`: Stream logs from postgres pod only
- `make logs-redis`: Stream logs from redis pod only
- Implementation: `kubectl logs -f -n wander-dev -l app={service}`

### Hot Reload Confirmation
- API: Nodemon logs "[nodemon] restarting due to changes..." to console
- Frontend: Vite logs "[vite] page reload src/..." to browser console
- Developer visibility: Check terminal where `make logs` is running
- No toast notifications (keep it simple)

### Healthcheck Timing Adjustments
- Postgres readiness: initialDelay 15s (allows startup time)
- Redis readiness: initialDelay 5s (starts quickly)
- API readiness: initialDelay 20s (allows migrations + DB connection)
- Frontend readiness: initialDelay 10s (allows build/serve startup)
- All: periodSeconds 5s, timeout 5s, failureThreshold 3

### Seed Script Re-run Behavior
- Command: `make seed-db`
- Behavior: Idempotent (checks if users table has data, skips if populated)
- Manual wipe: `make teardown && make dev` for fresh seed
- Implementation: Execute PL/pgSQL DO block via kubectl exec
- No destructive re-seed on running database

### Docker Image Naming Convention
- Format: `wander-{service}:latest`
- Examples: `wander-api:latest`, `wander-frontend:latest`, `wander-postgres:latest`
- Registry: Local only (no push to registry in demo)
- Tagging: Only `latest` tag (no version tags)
- Build: `docker build -t wander-api:latest -f services/api/Dockerfile .`

### envsubst Multi-line YAML Block Handling
- Strategy: Use placeholder variables for entire sections
- Implementation: Bash script generates volume YAML or empty string based on NODE_ENV
- Example:
  ```bash
  if [ "$NODE_ENV" = "development" ]; then
    export DEV_VOLUME_MOUNT=$(cat <<EOF
        volumeMounts:
          - name: api-src
            mountPath: /app/src
  EOF
  )
  else
    export DEV_VOLUME_MOUNT=""
  fi
  envsubst < template.yaml > generated/output.yaml
  ```
- Script: `scripts/prepare-manifests.sh` handles this logic

### Jest Test Configuration (root jest.config.js)
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  moduleNameMapper: {
    '^@wander/shared/(.*)$': '<rootDir>/packages/shared/dist/$1'
  },
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'services/api/src/**/*.ts',
    '!services/api/src/**/*.test.ts'
  ],
  testTimeout: 30000
};
```
- Execution: Serial (in band) via `--runInBand` flag
- Coverage: Enabled with `--coverage` flag
- Threshold: Not enforced (demo purposes)
- Reporter: Default (console)
- Timeout: 30 seconds per test

### Test Data Strategy
- Approach: Tests use same seed data as development
- No fixtures: Rely on database seed script for consistent data
- Assumptions: Tests know IDs (user 1, team 1, project 1, etc.)
- Cleanup: No cleanup needed (tests don't modify data, read-only assertions)
- Smoke tests only: Verify endpoints return expected status codes and basic structure

### Package Dependencies (Complete List)

**API Service (services/api/package.json)**:
```json
{
  "dependencies": {
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "knex": "^3.0.0",
    "pg": "^8.11.0",
    "ioredis": "^5.3.0",
    "pino": "^8.16.0",
    "dotenv": "^16.3.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.20",
    "@types/cors": "^2.8.16",
    "@types/node": "^20.10.0",
    "typescript": "^5.3.0",
    "ts-node": "^10.9.0",
    "nodemon": "^3.0.0",
    "tsconfig-paths": "^4.2.0"
  }
}
```

**Frontend Service (services/frontend/package.json)**:
```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0",
    "serve": "^14.2.0"
  }
}
```

**Shared Package (packages/shared/package.json)**:
```json
{
  "name": "@wander/shared",
  "dependencies": {},
  "devDependencies": {
    "typescript": "^5.3.0"
  }
}
```

**Root Package (package.json)**:
```json
{
  "devDependencies": {
    "jest": "^29.7.0",
    "@types/jest": "^29.5.0",
    "ts-jest": "^29.1.0"
  }
}
```

### TypeScript Configuration Details

**Base Config (tsconfig.base.json)** - Extended by all packages:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "lib": ["ES2020"],
    "esModuleInterop": true,
    "skipLibCheck": true,
    "strict": false,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

**API tsconfig.json** - Extends base, adds path aliases:
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "baseUrl": "./src",
    "paths": {
      "@/routes/*": ["routes/*"],
      "@/database/*": ["database/*"],
      "@/cache/*": ["cache/*"],
      "@/middleware/*": ["middleware/*"],
      "@/types/*": ["types/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Frontend tsconfig.json** - Extends base, adds React support:
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "jsx": "react-jsx",
    "outDir": "./dist",
    "baseUrl": "./src",
    "paths": {
      "@/pages/*": ["pages/*"],
      "@/components/*": ["components/*"],
      "@/api/*": ["api/*"],
      "@/types/*": ["types/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Shared tsconfig.json** - Extends base, minimal config:
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Vite Configuration (services/frontend/vite.config.ts)
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    host: '0.0.0.0'
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    chunkSizeWarningLimit: 1000,
    rollupOptions: {
      output: {
        manualChunks: undefined
      }
    }
  }
});
```
- Sourcemaps: Enabled in dev and prod
- Chunk size limit: 1000kb warning threshold
- Manual chunks: Disabled (let Vite decide)
- Assets: External by default (no inlining)

### Tailwind Configuration (services/frontend/tailwind.config.js)
```javascript
module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}', './index.html'],
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',
        secondary: '#8b5cf6'
      }
    }
  },
  plugins: []
};
```
- Use mostly defaults
- Custom primary (blue) and secondary (purple) colors
- No custom spacing or breakpoints

### PostCSS Configuration (services/frontend/postcss.config.js)
```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {}
  }
};
```
- Standard Tailwind + Autoprefixer setup
- No additional PostCSS plugins

### ESLint Configuration (root .eslintrc.json)
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/no-unused-vars": "warn",
    "no-console": "off"
  }
}
```
- Recommended ruleset only
- Allow `any` type (strict: false approach)
- Console logs allowed (useful for debugging)

### Database Schema Constraints
- **Foreign key cascade**: `ON DELETE CASCADE`, `ON UPDATE CASCADE`
- **Timestamps**: `created_at` uses `DEFAULT CURRENT_TIMESTAMP`, `updated_at` requires manual update (no trigger)
- Updated via application code: `UPDATE ... SET updated_at = CURRENT_TIMESTAMP WHERE id = ?`
- Rationale: Keep database simple, handle logic in application layer

### API Endpoint Conventions
- **Path format**: `/api/projects` (no trailing slash)
- **Trailing slash handling**: Express doesn't enforce, both work
- **Pagination empty**: Returns empty array `[]` if offset exceeds records
- **Update method**: PUT is full replacement (all fields required)
- **PATCH support**: Not implemented (keep simple with PUT only)
- **NULL vs empty string**: Missing optional fields stored as NULL, required fields reject if missing

### Frontend Component Architecture

**File structure**: One file per component with colocated styles
```
src/components/
  Modal.tsx          # Component with inline Tailwind classes
  TaskList.tsx
  ProjectCard.tsx
```

**API client pattern** (src/api/client.ts):
```typescript
const API_BASE = import.meta.env.VITE_API_URL;

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`);
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

export async function apiPost<T>(path: string, body: any): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

// Similar for apiPut, apiDelete
```
Usage in components: `const projects = await apiGet<Project[]>('/api/projects');`

**Loading states**: Minimal implementation
```typescript
const [loading, setLoading] = useState(true);
const [data, setData] = useState([]);

useEffect(() => {
  apiGet('/api/projects').then(setData).finally(() => setLoading(false));
}, []);

if (loading) return <div>Loading...</div>;
```

**Form handling**: Controlled inputs with React state
```typescript
const [name, setName] = useState('');
<input value={name} onChange={(e) => setName(e.target.value)} />
```

**Input validation**: 
- Client-side: Basic HTML5 validation (required, type="email")
- No complex validation library
- Server errors displayed below form fields

**Button states**: Disable during submission
```typescript
const [submitting, setSubmitting] = useState(false);
<button disabled={submitting}>Create</button>
```

**Action feedback**: Close modal on success (implies success), keep open and show error on failure
```typescript
try {
  await apiPost('/api/projects', data);
  onClose(); // Success implied by modal closing
} catch (err) {
  setError(err.message); // Show error in modal
}
```

### Error Handling & Network Behavior

**Frontend timeouts**: 30 seconds per request
```typescript
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 30000);
fetch(url, { signal: controller.signal });
```

**Retry logic**: No automatic retry (show error immediately)
- User can manually retry by clicking button again

**Concurrent updates**: Last write wins (no conflict detection)
- Optimistic UI not implemented (wait for server response)

**Connection pool exhaustion**: Knex queues requests automatically
- If queue grows too large, requests timeout after 30 seconds

**Migration rollback**: Manual only
- Developer must write down migration and run it manually
- No automatic rollback (exit on error, fix manually)

**Pod eviction handling**: In-flight requests fail with network error
- Frontend shows error, user can retry
- No automatic recovery or request replay

### Development Workflow Standards

**Branch strategy**: Single `main` branch only
- Commits directly to main (simple demo project)
- No PR process or branch protection

**Commit message format**: Freeform (no convention)
- Descriptive messages encouraged but not enforced

**Package manager**: npm only (lock file: package-lock.json)
- Do not use yarn or pnpm (avoid confusion)

**Node version**: Node 20 LTS
- File: `.nvmrc` with content `20`
- Developers run `nvm use` to switch

**VS Code settings** (.vscode/settings.json):
```json
{
  "editor.formatOnSave": false,
  "typescript.tsdk": "node_modules/typescript/lib",
  "files.eol": "\n"
}
```

**Debug configuration** (.vscode/launch.json):
```json
{
  "configurations": [
    {
      "type": "node",
      "request": "attach",
      "name": "Attach to API",
      "port": 9229,
      "restart": true,
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

### Build & Production Settings

**Source maps**:
- Development: Inline source maps (fast rebuild)
- Production: External source maps included (for debugging)
- Config: `"sourceMap": true` in tsconfig.json, Vite generates automatically

**Console logs in production**:
- Keep all console logs (useful for debugging)
- No stripping or removal
- Rationale: Demo app, production debugging may be needed

**Build output hashing**: Vite automatic hashing
- Example: `assets/index-a1b2c3d4.js`
- Enables cache busting automatically

**Environment detection**: `NODE_ENV` only
```typescript
const isDev = process.env.NODE_ENV === 'development';
```

**Graceful shutdown**: Basic implementation
```typescript
process.on('SIGTERM', async () => {
  console.log('Received SIGTERM, closing server...');
  server.close(() => {
    knex.destroy();
    redis.disconnect();
    process.exit(0);
  });
});
```
- Close HTTP server (stops accepting new requests)
- Wait for existing requests to complete (30s max)
- Close DB and Redis connections
- Exit cleanly

### Styling & UX Standards

**CSS reset**: Use Tailwind's preflight (built-in normalize)
- No additional reset needed

**Font family**: System font stack (no web fonts)
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
```

**Color palette**: Tailwind defaults + custom primary/secondary
- Primary: `#3b82f6` (blue-500)
- Secondary: `#8b5cf6` (violet-500)
- Use Tailwind color utilities: `bg-primary`, `text-secondary`

**Focus indicators**: Tailwind's default focus rings
- Enabled automatically with `focus:` variants
- Example: `focus:ring-2 focus:ring-primary`

**Dark mode**: Out of scope (not implemented)
- No toggle, no dark mode styles

### 19.1 API Response Formats - Sensible Defaults

**GET Endpoints (List)**:
```json
[
  { "id": 1, "name": "Project 1", ... },
  { "id": 2, "name": "Project 2", ... }
]
```

**GET Endpoints (Single)**:
```json
{ "id": 1, "name": "Project 1", "team_id": 1, ... }
```

**POST Endpoints (Create)**:
```json
{ "id": 1, "name": "New Project", ... }
```

**PUT Endpoints (Update)**:
```json
{ "id": 1, "name": "Updated Project", ... }
```

**DELETE Endpoints**:
```
204 No Content (empty response)
```

**Error Responses**:
```json
{ "message": "Error description" }
```

**Pagination Query Parameters**:
- `?limit=10&offset=0` (default: limit=10, offset=0)
- Array response only (no pagination metadata)### 16.2 Build Configuration - Sensible Defaults

**TypeScript Configuration**:
- API: `strict: false` (gradual typing)
- Frontend: `strict: false` (easier development)
- Target: ES2020
- Module: ESNext
- All `tsconfig.json` files include path aliases for cleaner imports

**Frontend Build Tools**:
- Vite configuration:
  - Dev server: `http://localhost:3000`
  - Build output: `dist/` folder
  - HMR enabled by default
  - React plugin for fast refresh
- Tailwind CSS:
  - Utility-first approach
  - Content: `src/**/*.{tsx,ts}`
  - Dark mode: not enabled (keep simple)

**Redis Persistence**:
- No volume mount (ephemeral cache)
- Data lost on container restart (acceptable for dev)
- Fresh Redis state each `make dev` run

**Makefile Verbosity**:
- `make dev` is verbose by default
- No flags needed
- All commands include descriptive output### 12.9 Kubernetes & Resource Configuration - Sensible Defaults

**Pod Replicas**:
- All services: 1 replica each (sufficient for local dev demo)
- Not needed: Service replicas or load balancing

**Healthcheck Probes**:
- Readiness: `GET /health/ready` checks DB + Redis connectivity
- Liveness: `GET /health` basic API responsiveness
- Initial delays: Postgres 15s, Redis 5s, API 20s, Frontend 10s
- Period: 5s for all services
- Timeout: 5s for all services
- Failure threshold: 3 attempts before restart

**Resource Configuration**:
- API: requests `100m CPU / 256Mi RAM`, limits `500m CPU / 512Mi RAM`
- Frontend: requests `50m CPU / 128Mi RAM`, limits `250m CPU / 256Mi RAM`
- PostgreSQL: requests `200m CPU / 256Mi RAM`, limits `1000m CPU / 512Mi RAM`
- Redis: requests `50m CPU / 128Mi RAM`, limits `250m CPU / 256Mi RAM`

**Networking**:
- All services: ClusterIP (internal-only)
- Simple names: `api`, `postgres`, `redis`, `frontend`
- No ingress controller
- Port-forward for host access### 12.8 Database & Indexing - Sensible Defaults

**Indexing Strategy**:
- Indexes on all foreign keys (for JOIN performance)
- Indexes on commonly searched fields (email, status, created_at)
- No composite indexes (keep it simple)
- No covering indexes

**Connection Management**:
- Connection string: `postgresql://postgres:dev_password@postgres:5432/warden_dev`
- Built from env vars, not a single URL var
- Pool size: 10 connections
- Fail fast on connection errors (no retry)

**Data Refresh**:
- Fresh database on each `make dev` run
- Seed script automatic on first container init
- Can be manually re-run with `make seed-db`
- Idempotent: skips if data already exists### 10.4 Frontend Implementation - Sensible Defaults

**State Management**:
- Component-level state only (useState for data fetching)
- No prop drilling (co-locate data with components that use it)
- Fetch fresh data on page load (no caching layer)

**User Interactions**:
- Create/edit via modal dialogs (simpler UX)
- Links: Project names, team names link to detail pages
- No search, sort, or filter UI (keep it minimal)
- Inline feedback: simple success/failure indication

**Frontend Build**:
- Output to `dist/` folder
- No gzip compression (serve handles it)
- External CSS and JS files (not inline)

**Browser Features**:
- Dates/times use browser locale automatically (via Intl API)
- No service workers or offline capability
- No internationalization beyond dates (English UI only)

**TypeScript Strictness**:
- `strict: false` in tsconfig.json (easier initial dev, fewer strict errors)
- Gradual typing approach (allows `any` where needed)### 9.2 API Implementation - Sensible Defaults

**Endpoint Capabilities**:
- No bulk operations (keep it simple)
- No filtering, sorting, or complex query params (just pagination)
- No soft deletes (hard delete with cascading)
- No transaction management (rely on DB constraints)
- Pagination: Return array directly `[...]` (no metadata wrapper)

**Error Handling Approach**:
- Let errors bubble up (no custom error middleware)
- Express returns 500 on uncaught errors
- Simple error format: `{ message: "Error description" }`
- HTTP status codes: 200 (success), 201 (created), 204 (deleted), 500 (error)

**Request Logging**:
- Log: method, path, status code, response time
- Simple format: `[14:32:10] GET /api/projects 200 (45ms)`
- Log to console only (no files)

**Database Connections**:
- Connection string built from env vars: `postgresql://USER:PASS@HOST:PORT/DB`
- No retry logic (fail fast on connection errors)
- Pool size: 10 connections (via Knex)

**CORS Configuration**:
- Allow from `http://localhost:3000` only (frontend origin)
- Allow methods: GET, POST, PUT, DELETE
- Allow headers: Content-Type### 14.3 Shared Code & Monorepo Structure

**Shared Package** (`packages/shared/`):
- TypeScript type definitions (User, Team, Project, Task, Activity)
- Constants (task statuses, priorities, team roles)
- Utility functions (validators, formatters, helpers)
- Imported by both API and frontend via npm workspaces

**Monorepo Structure** (npm workspaces):
```json
// Root package.json
{
  "workspaces": [
    "packages/shared",
    "services/api",
    "services/frontend"
  ]
}
```

**Import Pattern**:
```typescript
// In API: services/api/src/routes/tasks.ts
import { Task, TaskStatus } from '@wander/shared/types';

// In Frontend: services/frontend/src/pages/ProjectDetail.tsx
import { Project, Task } from '@wander/shared/types';
```

**Workspace Benefits**:
- Single `npm install` installs all dependencies
- Single `package-lock.json` ensures version consistency
- `npm run dev --workspaces` runs all dev servers
- Shared code changes instantly available to all services

**Compilation**:
- `packages/shared` compiles to `dist/` folder
- Services import from compiled `dist/` (not source)
- Keep compilation simple (tsc only)### 14.3 Shared Code & Monorepo Structure

**Repository Layout** (single Git repo, npm workspaces):
```
wander-dev-env/
├── package.json                      # Root workspace config
├── package-lock.json
├── tsconfig.base.json               # Base TypeScript config (extended by all packages)
├── jest.config.js                   # Jest test configuration
├── .eslintrc.json                   # ESLint configuration
├── Makefile
├── README.md
├── .env.example
├── .gitignore                       # Ignores: .env, .pids/, infra/generated/, node_modules, dist/
├── .editorconfig
├── .nvmrc                           # Node version (20)
├── .vscode/
│   ├── settings.json                # VS Code workspace settings
│   └── launch.json                  # Debug configurations
│
├── scripts/
│   ├── preflight-check.sh           # Validate Docker, kubectl, etc.
│   ├── wait-for-services.sh         # Poll service health
│   ├── handle-error.sh              # Common error recovery
│   ├── validate-seed.sh             # Verify seed script success
│   └── prepare-manifests.sh         # Generate YAML with envsubst + conditional blocks
│
├── infra/
│   ├── k8s/
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── postgres.yaml
│   │   ├── redis.yaml
│   │   ├── api.yaml
│   │   └── frontend.yaml
│   └── generated/                   # Generated manifests (gitignored)
│
├── packages/
│   └── shared/                      # Shared code between API and frontend
│       ├── package.json
│       ├── src/
│       │   ├── types/               # Shared TypeScript types
│       │   │   ├── user.ts
│       │   │   ├── team.ts
│       │   │   ├── project.ts
│       │   │   └── task.ts
│       │   └── constants/           # Shared constants
│       ├── tsconfig.json
│       └── dist/
│
├── services/
│   ├── api/
│   │   ├── package.json             # API dependencies + workspace reference
│   │   ├── tsconfig.json            # API TypeScript config (extends base)
│   │   ├── nodemon.json             # Nodemon configuration
│   │   ├── Dockerfile
│   │   ├── .dockerignore
│   │   ├── src/
│   │   │   ├── index.ts            # Express app entry point
│   │   │   ├── server.ts           # Server setup
│   │   │   ├── routes/
│   │   │   │   ├── users.ts
│   │   │   │   ├── teams.ts
│   │   │   │   ├── projects.ts
│   │   │   │   ├── tasks.ts
│   │   │   │   ├── activities.ts
│   │   │   │   └── health.ts
│   │   │   ├── database/
│   │   │   │   ├── connection.ts   # Knex setup
│   │   │   │   └── migrations/     # DB migrations (if needed)
│   │   │   ├── cache/
│   │   │   │   └── redis.ts        # Redis client setup
│   │   │   ├── middleware/
│   │   │   │   └── logging.ts      # Request logging
│   │   │   └── types/              # API-specific types
│   │   └── dist/                   # Compiled output (gitignored)
│   │
│   └── frontend/
│       ├── package.json             # Frontend dependencies + workspace reference
│       ├── tsconfig.json            # Frontend TypeScript config (extends base)
│       ├── vite.config.ts           # Vite configuration
│       ├── tailwind.config.js       # Tailwind CSS configuration
│       ├── postcss.config.js        # PostCSS configuration
│       ├── Dockerfile
│       ├── .dockerignore
│       ├── src/
│       │   ├── main.tsx            # Vite entry point
│       │   ├── App.tsx             # Root component
│       │   ├── pages/
│       │   │   ├── Dashboard.tsx
│       │   │   ├── Teams.tsx
│       │   │   ├── Projects.tsx
│       │   │   ├── ProjectDetail.tsx
│       │   │   └── Users.tsx
│       │   ├── components/
│       │   │   ├── Header.tsx
│       │   │   ├── Nav.tsx
│       │   │   ├── Footer.tsx
│       │   │   ├── UserList.tsx
│       │   │   ├── TeamList.tsx
│       │   │   ├── ProjectList.tsx
│       │   │   └── TaskList.tsx
│       │   ├── api/
│       │   │   └── client.ts       # Fetch wrapper
│       │   ├── styles/
│       │   │   └── tailwind.css
│       │   └── types/              # Frontend-specific types
│       ├── dist/                   # Build output (gitignored)
│       ├── public/                 # Static assets
│       ├── index.html
│       └── .env.example
│
├── db/
│   ├── init/
│   │   └── seed.sql               # Version-controlled seed script
│   └── Dockerfile                 # Postgres image
│
├── tests/
│   ├── integration.test.ts        # Simple integration tests
│   └── fixtures/                  # Test data
│
└── docs/
    ├── ARCHITECTURE.md            # System overview with diagrams
    ├── API.md                     # API endpoint reference with curl examples
    ├── DATABASE.md                # Schema documentation
    ├── KUBERNETES.md              # K8s concepts for developers
    ├── SETUP.md                   # Step-by-step setup guide
    ├── TROUBLESHOOTING.md         # Common issues and solutions
    ├── CONTRIBUTING.md            # Development guidelines
    └── images/                    # Architecture diagrams (ASCII/Mermaid)
```

**Root package.json Workspaces Configuration**:
```json
{
  "workspaces": [
    "packages/shared",
    "services/api",
    "services/frontend"
  ]
}
```

**Workspace Benefits**:
- Shared types live in `packages/shared` (imported by both API and frontend)
- Single `package-lock.json` for all dependencies
- `npm install` installs all workspace dependencies
- `npm run dev --workspaces` runs dev scripts for all services
- Consistent dependency versions across the monorepo

**NPM Scripts** (workspace commands):
- Root package.json:
  - `"dev": "npm run dev --workspaces"` - Start all dev servers
  - `"build": "npm run build --workspaces"` - Build all packages
  - `"test": "jest"` - Run integration tests
- Shared package (packages/shared):
  - `"build": "tsc"` - Compile TypeScript to dist/
  - `"dev": "tsc --watch"` - Watch mode for development
- API (services/api):
  - `"dev": "nodemon"` - Hot reload with nodemon
  - `"build": "tsc"` - Compile to dist/
  - `"start": "node dist/index.js"` - Production start
- Frontend (services/frontend):
  - `"dev": "vite"` - Vite dev server with HMR
  - `"build": "vite build"` - Production build
  - `"preview": "vite preview"` - Preview production build

### 12.7 Testing & Validation

**Health Check Endpoints**:
- `GET /health` - Lightweight liveness probe (< 100ms response)
- `GET /health/ready` - Full readiness probe with dependencies:
  - Database connectivity (SELECT 1 query)
  - Redis connectivity (PING command)
  - Response time < 1 second
  - Response: `{ status: "ok", timestamp: "2025-11-11T...", services: { db: "connected", redis: "connected" } }`

**Kubernetes Health Probes** (all pods):
```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 4000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 5
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /health
    port: 4000
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

**Seed Script Validation**:
- Seed runs on container init via `docker-entrypoint-initdb.d/seed.sql`
- Idempotent check: exits silently if data exists
- Verbose success: logs row counts on successful seed
- Row count verification with comments in SQL### 12.6 Demo Application Data Model

**Data Relationships**:
- **User** → can belong to multiple **Teams** (via team_members)
- **Team** → contains multiple **Users** and **Projects**
- **Project** → belongs to one **Team**, contains multiple **Tasks**
- **Task** → belongs to one **Project**, assigned to at most one **User**
- **Activity** → references a **User**, tracks entity changes

**Minimal Mock Data** (5 users, 2 teams, 2 projects, 6 tasks):
- Realistic but lightweight for quick comprehension
- Demonstrates all relationships without clutter
- Seed script handles idempotency

**Task Assignment & Status**:
- Tasks can be assigned to one user or unassigned (null)
- Status progression: `todo` → `in_progress` → `done`
- Some tasks intentionally unassigned to show null handling

**Activity Log**:
- 10 sample entries showing realistic user actions
- Mix of task creation, status updates, assignments
- Timestamps spread across 7-day window for realistic timeline### 12.5 Logging & Observability

**Logging Strategy**:
- Console output for all services (stdout/stderr captured by Kubernetes)
- Structured JSON logging from API (for prod-readiness and machine parsing)
- Timestamps in UTC (ISO 8601 format)
- Log levels: debug (dev), info, warn, error
- API logs request/response metadata (method, path, status, duration)

**Startup Output**:
```
🚀 Starting Zero-to-Running Developer Environment...
📋 Platform: darwin (macOS)
✅ Dependencies verified
🔨 Building Docker images...
  ✅ wander-api:latest
  ✅ wander-frontend:latest
🎯 Applying Kubernetes manifests...
⏳ Waiting for all services to be healthy...
  ⏳ postgres: starting...
  ⏳ redis: starting...
  ✅ postgres: ready
  ✅ redis: ready
  ⏳ api: starting...
  ⏳ frontend: starting...
  ✅ api: ready
  ✅ frontend: ready
✅ Environment is ready!
📝 Access your environment:
   Frontend:  http://localhost:3000
   API:       http://localhost:4000
```

**Real-Time Logs** (`make logs`):
- Streams logs from all pods in parallel
- Color-coded by service (different colors for api, frontend, postgres, redis)
- Timestamps on each line
- Press Ctrl+C to stop streaming### 12.8 Build Tools & Development Experience

**Makefile Compatibility**:
- Primary: GNU Make (default on Linux, via Xcode CLT on macOS)
- Secondary: BSD Make (macOS default) - uses portable POSIX syntax
- Windows: Git Bash or WSL2
- All Make commands tested on Ubuntu, macOS (Intel/Silicon), Windows WSL2

**Makefile Commands** (all documented via `make help`):
- `make dev` - Start environment (runs preflight, envsubst, build, deploy, port-forward)
- `make teardown` - Stop and clean up everything (kills port-forwards, deletes namespace)
- `make restart` - Shortcut for teardown + dev in one command
- `make logs` - Stream real-time logs from all pods
- `make logs-api` - Stream logs from API pod only
- `make logs-frontend` - Stream logs from frontend pod only
- `make logs-postgres` - Stream logs from postgres pod only
- `make logs-redis` - Stream logs from redis pod only
- `make status` - Show pod status and health
- `make seed-db` - Manually reseed database (idempotent, exec seed.sql in postgres pod)
- `make build` - Just build Docker images (don't deploy)
- `make test` - Run Jest integration tests (serial execution with coverage)
- `make shell-api` - Open shell in API pod for debugging
- `make db-shell` - Open psql in database pod
- `make clean` - Remove Docker images (force fresh build next time)
- `make help` - Show all available commands with descriptions

**Shell Scripts**:
- Bash (`#!/bin/bash`) for all scripts
- POSIX-compatible syntax for portability
- Error handling: `set -e` (exit on error)
- Path normalization (forward slashes)

**Development Experience**:
- Hot reload enabled: nodemon (API) + Vite HMR (frontend)
- Source code mounted as volumes (instant changes)
- Component state preserved across reloads (Vite default)
- TypeScript compilation errors logged to console (warn, don't block)
- Exposed debug ports: API port 9229 (Node Inspector)
- All services restart on crash (Kubernetes default behavior)## 16. Configuration & Environment

**Environment Variables** (from `.env.example`, gitignored at runtime):
```bash
# Database
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=wander_dev
DATABASE_USER=postgres
DATABASE_PASSWORD=dev_password
DATABASE_POOL_SIZE=10

# API
API_HOST=0.0.0.0
API_PORT=4000
API_DEBUG_PORT=9229
API_LOG_LEVEL=debug
NODE_ENV=development

# Frontend
FRONTEND_HOST=0.0.0.0
FRONTEND_PORT=3000
VITE_API_URL=http://api:4000

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# General
ENVIRONMENT=development
```

**Environment Management**:
- `.env.example` committed to repo (template)
- `.env` gitignored (local overrides, created on first run from example)
- Development defaults suitable for local setup
- Console logging in JSON format (structured logs)
- Debug mode enabled via `LOG_LEVEL=debug` env var

**Secrets Handling**:
- Database password: `dev_password` (acceptable for local dev)
- No real secrets in `.env.example` (safe to commit)
- Framework for production secret injection documented (e.g., environment variable override pattern)### 12.2 Database & Seed Script

**Seed Script Characteristics** (`db/init/seed.sql`):
- **Version-controlled**: Part of repository for consistency
- **Idempotent**: Checks if data already exists, skips if populated
- **Initial Drop**: `DROP TABLE IF EXISTS ... CASCADE;` ensures clean state
- **Primary Keys**: Auto-incrementing SERIAL integers
- **Timestamps**: All in UTC using `CURRENT_TIMESTAMP`
- **Validation**: Includes row count checks with comments

**Seed Script Behavior** (PL/pgSQL Implementation):
```sql
-- Idempotent seed script using PL/pgSQL DO block
DO $$
DECLARE
  user_count INTEGER;
BEGIN
  -- Check if already populated
  SELECT COUNT(*) INTO user_count FROM users;
  
  IF user_count > 0 THEN
    RAISE NOTICE 'Database already seeded. Skipping seed script.';
    RETURN;
  END IF;

  -- Drop existing tables to ensure clean state
  DROP TABLE IF EXISTS activities CASCADE;
  DROP TABLE IF EXISTS tasks CASCADE;
  DROP TABLE IF EXISTS projects CASCADE;
  DROP TABLE IF EXISTS team_members CASCADE;
  DROP TABLE IF EXISTS teams CASCADE;
  DROP TABLE IF EXISTS users CASCADE;

  -- Create tables and insert seed data...
  -- (Full table definitions and INSERT statements)
  
  RAISE NOTICE 'Database seeded successfully: 5 users, 2 teams, 2 projects, 6 tasks, 10 activities';
END $$;
```

**Expected counts after seeding**:
- 5 users
- 2 teams
- 2 projects (via team relationships)
- 6 tasks
- 10 activities

**Post-Seed Validation**:
- Query each table to verify row counts
- Log success: `✅ Database seeded successfully: 5 users, 2 teams, 2 projects, 6 tasks, 10 activities`
- If counts don't match expected values, log warning but don't fail (data may be valid)

**Database Connection**:
- URL format: `postgresql://postgres:PASSWORD@HOST:5432/warden_dev`
- Connection pooling: Knex default pool (10 connections)
- Timeout: 30 seconds
- Idle timeout: 30 seconds### 12.1 Troubleshooting & Error Handling

**Pre-Flight Checks** (verbose output, executed by `make dev`):
- ✅ Docker installed and running
- ✅ Kubernetes cluster available and configured
- ✅ kubectl CLI tool available
- ✅ envsubst available
- ✅ Disk space check (warn if < 10GB)
- ✅ Memory check (warn if < 4GB)
- ✅ OS detection (macOS, Linux, Windows WSL2)
- ✅ All checks log status to console (verbose by default)

**Common Error Scenarios & Beginner-Friendly Handling**:

| Error | Solution |
|-------|----------|
| Docker daemon not running | "❌ Docker is not running. Start Docker Desktop and try again." |
| Kubernetes cluster not found | "❌ Kubernetes not configured. Enable in Docker Desktop or install Minikube." |
| Port already in use | "❌ Port 4000 is in use. Stop the app using it or change API_PORT in .env" |
| Service failed to start | "❌ API pod failed to start. Run `make logs` to see error details." |
| Seed script failed | "❌ Database seeding failed. Check db/init/seed.sql for syntax errors." |
| Cannot connect to database | "⏳ Database not ready yet. Waiting... (this can take 30 seconds)" |

**Service Startup Validation**:
- Poll `/health/ready` on all services until ready
- Retry up to 60 times with 5-second intervals (5-minute max wait)
- If service timeout, extract and display pod logs
- Suggest remediation steps based on error type

**Password & Key Redaction**:
- Database password redacted in logs: `DATABASE_PASSWORD=***`
- API keys redacted: `API_KEY=***`
- Only show first 4 and last 4 characters of sensitive values
- Occurs in all console output and log streaming### 11.2 Kubernetes Networking Architecture

**Service Discovery & Pod Communication**:
- All services use **ClusterIP** services (internal-only, default Kubernetes service type)
- Internal DNS: `<service-name>.<namespace>.svc.cluster.local` or short form `<service-name>` within namespace
- Kubernetes CoreDNS handles automatic service discovery

**Service Definitions**:
```yaml
# API Service (ClusterIP)
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

# Similar pattern for postgres, redis, frontend
```

**Pod-to-Pod Communication**:
- API → PostgreSQL: DNS name `postgres:5432`
- API → Redis: DNS name `redis:6379`
- Frontend → API: DNS name `api:4000` (from inside pod)
- Kubernetes resolves these automatically

**Host Access (Port-Forward)**:
- Frontend: `kubectl port-forward svc/frontend 3000:3000`
- API: `kubectl port-forward svc/api 4000:4000`
- Database: `kubectl port-forward svc/postgres 5432:5432`
- Redis: `kubectl port-forward svc/redis 6379:6379`

**Pod Readiness & Liveness Probes**:
```yaml
# All pods include these probes
readinessProbe:
  httpGet:
    path: /health/ready
    port: 4000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 5
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /health
    port: 4000
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

**Resource Requests & Limits**:
- API: requests `100m CPU / 256Mi RAM`, limits `500m CPU / 512Mi RAM`
- Frontend: requests `50m CPU / 128Mi RAM`, limits `250m CPU / 256Mi RAM`
- PostgreSQL: requests `200m CPU / 256Mi RAM`, limits `1000m CPU / 512Mi RAM`
- Redis: requests `50m CPU / 128Mi RAM`, limits `250m CPU / 256Mi RAM`### 11.1 Docker Strategy

**Multi-Stage Dockerfiles** (one per service with environment-aware configuration):

**API Dockerfile** (`services/api/Dockerfile`):
```
Stage 1 - Builder:
  - Base: node:20-alpine
  - Install dependencies: npm ci
  - Compile TypeScript: npm run build
  - Artifact: /app/dist, /app/node_modules (prod only)

Stage 2 - Runtime:
  - Base: node:20-alpine
  - Copy dist and production dependencies from builder
  - Expose port 4000 (API) and 9229 (debug/inspector)
  - Healthcheck: curl -f http://localhost:4000/health/ready
  - ENV NODE_ENV=production (default)
  - CMD: node dist/index.js
  - Dev override: nodemon (mounts /app/src volume)
```

**Frontend Dockerfile** (`services/frontend/Dockerfile`):
```
Stage 1 - Builder:
  - Base: node:20-alpine
  - Install dependencies: npm ci
  - Build with Vite: npm run build
  - Artifact: /app/dist

Stage 2 - Runtime:
  - Base: node:20-alpine
  - Install serve: npm install -g serve (lightweight HTTP server)
  - Copy dist from builder
  - Expose port 3000
  - Healthcheck: curl -f http://localhost:3000/
  - CMD: serve -s dist -l 3000
  - Dev override: npm run dev (mounts /app/src, Vite HMR enabled)
```

**PostgreSQL Dockerfile** (`db/Dockerfile`):
```
Base: postgres:14-alpine
- Copy seed script to /docker-entrypoint-initdb.d/seed.sql
- POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD via environment
- Expose port 5432
- Healthcheck: pg_isready -U postgres -d wander_dev
```

**Redis Dockerfile** (`services/redis/Dockerfile`):
```
Base: redis:7-alpine
- Expose port 6379
- Healthcheck: redis-cli ping
- No authentication (local dev)
- Ephemeral storage (no persistence)
```

**Environment-Aware Execution**:
- Dev mode: `NODE_ENV=development` with source volumes mounted
- Prod mode: `NODE_ENV=production` with compiled code baked in
- Kubernetes deployment controls which mode via environment variables### 10.3 Frontend Implementation Details

**Framework & Libraries**:
- React 18+ with TypeScript (^18.2.0)
- Vite as build tool and dev server (^5.0.0, fast refresh with HMR)
- React Router v6 for multi-page navigation (^6.20.0)
- Tailwind CSS for styling (^3.4.0)
- Fetch API for HTTP requests (native browser API)
- serve for production static file serving
- Layout components: Header/Nav, main content area, Footer

**Frontend Characteristics**:
- React Router with conditional routing (`<Routes>`)
- Data fetching on component mount via `useEffect`
- Local component state only (useState)
- No global state management, form validation, loading states, or error boundaries
- Simple fetch wrapper for API calls (auto JSON parsing)
- Timestamps displayed in browser's local timezone via `Intl.DateTimeFormat`
- Console logging for debugging

**Development Mode**:
- Vite dev server with fast refresh (HMR) - preserves component state across reloads
- Source code mounted as volume for hot reload
- Sourcemaps enabled for debugging
- TypeScript compilation errors logged to console (don't block reload)
- Environment variables from `.env` file

**Production Build**:
- Vite optimized bundle (code splitting, tree-shaking)
- Served from lightweight Node.js HTTP server
- Minimal npm dependencies (reduce bundle size)

**Frontend Pages**:
- **Dashboard**: List recent activities, team/project quick links, task count summary
- **Teams**: List all teams with member count
- **Projects**: List all projects grouped by team
- **Project Detail**: Project info, task list with inline status indicator
- **Users**: Directory of all team members with assigned task count### 9.1 API Implementation Details

**Framework & Libraries**:
- Express.js for HTTP server (^4.18.0)
- Knex.js for SQL query building and database abstraction (^3.0.0)
- node-postgres (`pg`) for PostgreSQL driver
- Connection pooling via Knex's built-in pool configuration
- ioredis for Redis caching layer integration
- TypeScript for type safety (^5.3.0)
- cors for CORS handling
- pino for structured logging (production mode)

**API Characteristics**:
- Knex queries for all database operations (type-safe, SQL building)
- Redis caching for activities endpoint (cache-aside pattern with TTL)
- Direct data return in responses (no wrapper object)
- List endpoints support `limit` and `offset` query parameters (default limit: 10)
- All timestamps in UTC, returned as ISO 8601 strings
- Structured JSON logging to console (with redacted passwords/keys)
- Auto-restart on code changes (nodemon in dev mode)

**Health Checks**:
- `GET /health` - Basic liveness check (instant response)
- `GET /health/ready` - Full readiness check (DB and Redis connectivity)
  - Response: `{ status: "ok", timestamp: "2025-11-11T...", services: { db: "connected", redis: "connected" } }`
  - Used by Kubernetes readiness probe
  
**Response Formats**:
- GET (list): `[{ id, name, ... }, ...]`
- GET (single): `{ id, name, ... }`
- POST (create): `{ id, name, ... }` (full object)
- PUT (update): `{ id, name, ... }` (full object)
- DELETE: `204 No Content` (empty response)### Kubernetes Networking Architecture

**Service Discovery**:
- All services use **ClusterIP** (internal-only) services for inter-pod communication
- Services accessible via DNS: `<service-name>.<namespace>.svc.cluster.local`
- Within namespace, simple name resolution: `postgres:5432`, `redis:6379`, `api:4000`

**Service Connectivity**:
- API connects to PostgreSQL at: `postgres.wander-dev.svc.cluster.local:5432`
- API connects to Redis at: `redis.wander-dev.svc.cluster.local:6379`
- Frontend connects to API at: `http://api.wander-dev.svc.cluster.local:4000` (from inside cluster)
- Frontend exposed via port-forward: `http://localhost:3000` (from host)
- API exposed via port-forward: `http://localhost:4000` (from host)

**Port Exposure Strategy**:
- Database (PostgreSQL): Internal only, exposed via port-forward for development
- Cache (Redis): Internal only, exposed via port-forward for development (optional)
- API: ClusterIP service + port-forward to localhost:4000
- Frontend: ClusterIP service + port-forward to localhost:3000

**No Ingress** (kept simple for local development)### Dockerfile Strategy

**Multi-Stage Dockerfiles** (one per service):
- **API Dockerfile**:
  - Build stage: Install dependencies, compile TypeScript
  - Runtime stage: Node.js runtime with only production dependencies
  - Expose port 4000 and debug port 9229
  - CMD runs nodemon in dev (hot reload)
  
- **Frontend Dockerfile**:
  - Build stage: Install dependencies, prepare build artifacts
  - Runtime stage: Lightweight web server (serve or similar)
  - Expose port 3000
  - CMD runs dev server with hot reload
  
- **PostgreSQL Dockerfile**:
  - Base: Official postgres:14 image
  - Copy seed script to /docker-entrypoint-initdb.d/
  - Seed runs automatically on container initialization
  
- **Redis Dockerfile**:
  - Base: Official redis:7 image (minimal customization needed)- **Logging & Debugging**
  - Real-time feedback during `make dev` startup with progress indicators
  - `make logs` command for real-time log streaming from all services in parallel
  - Exposed debug ports for API (port 9229 for Node.js Inspector Protocol)
  - Hot reload enabled for API (nodemon or ts-node-dev) and frontend (React dev server)
  - Meaningful output showing which services are starting, their dependencies, and health status

- **Documentation**
  - Comprehensive README with step-by-step setup instructions
  - SETUP.md with detailed prerequisite verification
  - TROUBLESHOOTING.md with common errors and solutions
  - ARCHITECTURE.md explaining system design
  - API.md documenting all endpoints with examples
  - DATABASE.md showing schema and relationships
  - KUBERNETES.md explaining K8s concepts for developers

- **Status Monitoring** (`make status`)
  - Quick command to check pod health, readiness, and resource usage
  - Pod status, restart counts, and container logs### Setup & Teardown
- ✅ `make dev` completes successfully and brings all services to healthy state
- ✅ All services (frontend, API, database, cache) are running and healthy
- ✅ `make teardown` cleanly removes all resources
- ✅ Second run of `make dev` works without conflicts

### Cross-Platform Compatibility
- ✅ Setup works on Windows 10/11 with WSL2
- ✅ Setup works on macOS (Intel and Apple Silicon)
- ✅ Setup works on Linux (Ubuntu/Debian/CentOS/Fedora)
- ✅ No platform-specific manual steps required

### Demo Application
- ✅ Frontend loads successfully at http://localhost:3000
- ✅ Frontend displays teams, projects, and tasks from mock data
- ✅ API endpoints respond with correct mock data
- ✅ Can create, read, update, delete through API
- ✅ Can navigate through all demo pages in frontend
- ✅ Database contains expected seed data after startup

### Logging & Debugging
- ✅ `make logs` streams live logs from all services
- ✅ Real-time feedback during `make dev` shows progress
- ✅ Clear error messages for common issues
- ✅ Service status visible via `make status`

### Configuration & Customization
- ✅ Default `.env` values work out-of-the-box
- ✅ Template variables can be overridden via environment
- ✅ Configuration changes don't require code modifications
- ✅ YAML files clearly documented with variable substitution# Zero-to-Running Developer Environment - Implementation PRD

**Organization:** Wander  
**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Date:** November 2025

---

## 1. Executive Summary

The Zero-to-Running Developer Environment is an innovative solution by Wander that revolutionizes how developers set up their local development environments. This product enables new engineers to clone a repository, execute a single command (`make dev`), and instantly have a fully functional, multi-service application environment running locally. The solution eliminates manual setup steps, addresses common "works on my machine" problems, and dramatically reduces developer onboarding time.

The environment supports a complete tech stack:
- **Frontend**: TypeScript, React, Tailwind CSS
- **Backend API**: Node.js with TypeScript
- **Database**: PostgreSQL
- **Cache**: Redis

This tool is designed to boost developer productivity by enabling developers to focus on writing code rather than managing infrastructure.

---

## 2. Problem Statement

Developers frequently face significant delays and frustrations due to:
- Complex and inconsistent local environment setups
- Non-productive time spent troubleshooting "works on my machine" problems
- Manual configuration of dependencies and infrastructure
- Environment-related support tickets and knowledge transfer overhead
- Inconsistent setup across different operating systems (Windows, macOS, Linux)
- Steep onboarding curves for new team members

The goal of this product is to enable developers to focus on writing code rather than environment management, thereby increasing productivity and reducing onboarding time to near-zero.

---

## 3. Goals & Success Metrics

### Goals
- Minimize time spent on environment setup and management
- Enable cross-platform (Windows, macOS, Linux) seamless development
- Create a single source of truth for environment configuration
- Demonstrate full-stack integration out-of-the-box
- Reduce environment-related support tickets

### Success Metrics
- Reduction in setup time for new developers (target: < 10 minutes from clone to running)
- Increase in time spent writing code versus managing infrastructure
- Reduction in environment-related support tickets (target: 90% reduction)
- Zero "works on my machine" issues related to environment setup
- 100% developer adoption rate

---

## 4. Target Users & Personas

### Target Users
- **Primary**: Software engineers newly onboarded to a team
- **Secondary**: Engineers frequently switching between projects or services
- **Tertiary**: DevOps/Ops engineers maintaining infrastructure templates

### Personas

#### Persona 1: New Developer (Alex)
- **Background**: Fresh hire, 0-2 years experience
- **Pain Points**: Overwhelmed by setup complexity, unclear debugging steps, unsure if environment is working correctly
- **Goals**: Get productive quickly, understand the full stack architecture, write code on day one
- **Needs**: Clear documentation, obvious feedback, working examples

#### Persona 2: Ops-Savvy Engineer (Jamie)
- **Background**: Experienced developer, 5+ years experience with strong infrastructure knowledge
- **Pain Points**: Time wasted on repetitive setup, inconsistent configurations across team
- **Goals**: Streamlined processes, customizable configuration, maintainable solution
- **Needs**: Configuration file access, ability to override defaults, clear extension points

---

## 5. User Stories

1. **As a new developer**, I want to clone the repository and run a single command (`make dev`) to set up my environment so that I can start coding immediately without configuration complexity.

2. **As an ops-savvy engineer**, I want to configure my environment using YAML config files with template variables so that I can customize it according to my preferences without modifying core scripts.

3. **As a developer**, I want to see clear, real-time feedback during the setup process so that I know if everything is working correctly and can troubleshoot issues quickly.

4. **As a developer**, I want to tear down my environment with a single command (`make teardown`) to maintain a clean development setup with no orphaned resources.

5. **As a developer**, I want to see a functional demo application with real data flowing through the entire stack so that I can verify all services are working and understand the architecture.

6. **As a developer on Windows**, I want the environment setup to work seamlessly without needing special configuration for my operating system.

---

## 6. Technical Requirements

### 6.1 System Architecture

**Orchestration**: Kubernetes (local deployment for development)
- **Local Kubernetes Options**: Docker Desktop Kubernetes, Minikube, or Kind
- **Target Deployment**: Google Kubernetes Engine (GKE) for team environments
- **Containerization**: Docker with multi-stage Dockerfiles for all services

**Service Components**:
1. **PostgreSQL Database** (v14+)
   - Fresh database created on each startup (no persistent volumes)
   - Automatic initialization with versioned seed script
   - Health checks for readiness
   - Internal communication via ClusterIP Service and Kubernetes DNS

2. **Redis Cache** (v7+)
   - In-memory data store
   - Activity log caching
   - Health checks for liveness
   - Internal communication via ClusterIP Service and Kubernetes DNS

3. **Backend API** (Node.js with TypeScript)
   - Express.js framework
   - Simple RESTful endpoints (CRUD operations)
   - Hot reload capability via nodemon or ts-node-dev
   - Debug ports exposed for development
   - Internal communication via Kubernetes DNS (connects to postgres and redis by service name)
   - Simplified error handling (let errors propagate)

4. **Frontend Application** (React with TypeScript)
   - Tailwind CSS for styling
   - Connected to backend API
   - Standard React dev server with fast refresh
   - Real-time logs for debugging
   - No state management, form validation, loading states, or error boundaries
   - No authentication flow

### 10.3 Configuration Management

**Format**: YAML with template variable substitution  
**Tool**: `envsubst` for template variable replacement  
**Environment Variables**: Stored in version-controlled `.env.example` file, copied to `.env` for local overrides

**Format**: YAML with template variable substitution  
**Tool**: `envsubst` for template variable replacement  
**Environment Variables**: Stored in version-controlled `.env.example` file, copied to `.env` for local overrides

**Configuration Files**:
- `k8s/namespace.yaml` - Kubernetes namespace definition
- `k8s/configmap.yaml` - Centralized configuration (ports, log levels)
- `k8s/postgres.yaml` - Database deployment and ClusterIP service
- `k8s/redis.yaml` - Cache deployment and ClusterIP service
- `k8s/api.yaml` - Backend API deployment and ClusterIP service
- `k8s/frontend.yaml` - Frontend deployment and ClusterIP service

**Template Variables** (from `.env.example`):
- `DATABASE_PASSWORD` - PostgreSQL password
- `API_PORT` - Backend API port (default: 4000)
- `FRONTEND_PORT` - Frontend port (default: 3000)
- `DATABASE_PORT` - PostgreSQL port (default: 5432)
- `REDIS_PORT` - Redis port (default: 6379)
- `LOG_LEVEL` - Application log level (default: debug)

### 10.4 Cross-Platform Support

**Operating Systems Supported**:
- macOS (Intel and Apple Silicon)
- Linux (Ubuntu, Debian, CentOS, Fedora)
- Windows 10/11 (with WSL2 or Docker Desktop Kubernetes)

**Platform Handling**:
- Makefile detects OS using `uname -s`
- Path handling normalized across all platforms
- Volume mounts configured for compatibility on Windows WSL2
- Line ending compatibility (CRLF vs LF) handled in scripts

**Prerequisites**:
- Docker Desktop or Docker Engine (with Kubernetes enabled for Docker Desktop)
- Kubernetes cluster (local: Minikube, Kind, or Docker Desktop Kubernetes)
- `kubectl` CLI tool
- `envsubst` (GNU gettext) for template processing
- `make` utility (pre-installed on macOS/Linux; available via Git Bash on Windows)

---

## 7. Functional Requirements

### P0: Must-Have Features

- **Single Command Startup** (`make dev`)
  - Brings up entire stack with all services running and healthy
  - Performs automatic dependency ordering (DB starts before API)
  - Shows clear, real-time progress feedback

- **Configuration & Customization**
  - Externalized configuration in YAML files with template variables
  - Allow customization without modifying core scripts
  - Support for `.env` files for sensitive values
  - Secure handling of mock secrets demonstrating real secret management patterns

- **Service Orchestration**
  - Inter-service communication enabled (API ↔ DB, API ↔ Cache)
  - Health checks for all services confirming operational status
  - Automatic service dependency ordering
  - Graceful error handling for common issues (port conflicts, missing dependencies)

- **Data & Seeding**
  - Database seed script (`db/init/seed.sql`) with realistic mock data
  - Fresh database on each startup (no persistent storage between teardowns)
  - Seed script version-controlled for consistency and reproducibility
  - Separate `make seed-db` command for manual reseeding without full restart
  - Mock data simulates realistic developer onboarding scenario

- **Environment Teardown** (`make teardown`)
  - Single command to tear down entire environment cleanly
  - Removes all Kubernetes resources and generated files
  - Fully automated with no manual cleanup required
  - Removes persistent data to ensure fresh state

- **Logging & Debugging**
  - Meaningful output and logging during startup process
  - `make logs` command for real-time log streaming from all services
  - Exposed debug ports for API (port 9229 for Node.js Inspector)
  - Developer-friendly defaults (hot reload enabled for all services)

- **Documentation**
  - Comprehensive README with setup instructions
  - Troubleshooting guide for common errors
  - Architecture documentation
  - API endpoint documentation
  - Database schema documentation

- **Status Monitoring** (`make status`)
  - Quick command to check health of all services
  - Pod status and readiness indicators

---

## 8. Mock Data & Demo Application

### 8.2 Database Schema

**Design Principles**:
- All primary keys: Auto-incrementing SERIAL integers
- All timestamps: UTC timezone, `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
- Soft deletes: Not used (hard delete with cascading)
- Audit trail: `created_at` and `updated_at` on all entity tables

#### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

#### Teams Table
```sql
CREATE TABLE teams (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Team Members Junction Table
```sql
CREATE TABLE team_members (
  id SERIAL PRIMARY KEY,
  team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(team_id, user_id)
);

CREATE INDEX idx_team_members_user_id ON team_members(user_id);
CREATE INDEX idx_team_members_team_id ON team_members(team_id);
```

#### Projects Table
```sql
CREATE TABLE projects (
  id SERIAL PRIMARY KEY,
  team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_projects_team_id ON projects(team_id);
```

#### Tasks Table
```sql
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  assigned_to INTEGER REFERENCES users(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'todo',
  priority VARCHAR(50) DEFAULT 'medium',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_status ON tasks(status);
```

#### Activity Log Table
```sql
CREATE TABLE activities (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100),
  entity_id INTEGER,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activities_user_id ON activities(user_id);
CREATE INDEX idx_activities_created_at ON activities(created_at);
```

### 8.3 Mock Data Set

#### Data Characteristics
- **Schema**: Multi-table relational design with foreign key relationships
- **Seed Script**: Version-controlled SQL file (`db/init/seed.sql`)
- **Refresh Strategy**: Fresh data on every startup (clean database on container initialization)
- **Realistic Scenario**: Team collaboration and project management workflow

#### Users (5 total)
- Alice Chen (alice@wander.com) - Frontend Lead
- Bob Martinez (bob@wander.com) - Backend Lead
- Carol Singh (carol@wander.com) - Full Stack
- David Lee (david@wander.com) - DevOps
- Emma Johnson (emma@wander.com) - Frontend Developer

#### Teams (2 total)
- Frontend Squad (Alice Chen, Emma Johnson, Carol Singh)
- Backend Brigade (Bob Martinez, David Lee)

#### Projects (2 total)
1. **Dashboard Redesign** (Frontend Squad)
   - Status: active
   - Description: Modernize the main dashboard UI with new design system

2. **API v2 Migration** (Backend Brigade)
   - Status: active
   - Description: Migrate from REST to GraphQL with improved performance

#### Tasks (6 total)
- Dashboard Redesign (3 tasks)
- API v2 Migration (3 tasks)

Task statuses: todo, in_progress, done
Task priorities: low, medium, high

#### Activity Log (10 sample entries)

### 8.4 Redis Usage

- **Session Cache**: User session data (TTL: 24 hours)
- **Activity Feed**: Recent activities cached for quick retrieval (TTL: 1 hour)
- **API Response Cache**: Frequently accessed data (TTL: 5 minutes)

---

## 9. API Endpoints (Functional Demo)

### Base URL
```
http://localhost:4000/api
```

### Endpoints

#### Users
- `GET /users` - List all users
- `GET /users/:id` - Get user details
- `POST /users` - Create new user
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user

#### Teams
- `GET /teams` - List all teams
- `GET /teams/:id` - Get team details with members
- `POST /teams` - Create new team
- `POST /teams/:id/members` - Add user to team
- `DELETE /teams/:id/members/:userId` - Remove user from team

#### Projects
- `GET /projects` - List all projects
- `GET /projects/:id` - Get project details with tasks
- `POST /projects` - Create new project
- `PUT /projects/:id` - Update project
- `DELETE /projects/:id` - Delete project

#### Tasks
- `GET /tasks` - List all tasks
- `GET /tasks/:id` - Get task details
- `POST /tasks` - Create new task
- `PUT /tasks/:id` - Update task (including status)
- `DELETE /tasks/:id` - Delete task
- `GET /tasks/assigned/:userId` - Get tasks assigned to user

#### Activities
- `GET /activities` - List recent activities
- `GET /activities/user/:userId` - Activities by specific user

#### Health
- `GET /health` - Basic service health check
- `GET /health/ready` - Full readiness check (includes DB and Redis connectivity)

---

## 10. Frontend Demo Pages

### React Components & Pages

#### Dashboard Page
- Display recent activities from all teams
- Quick stats (tasks in progress, projects active)
- Navigation to other sections

#### Teams Page
- List all teams
- Team member information
- Link to team projects

#### Projects Page
- List all projects by team
- Project status indicators
- Link to project tasks

#### Project Detail Page
- Project overview and description
- Task list with status indicators
- Ability to create/edit tasks
- Task assignment UI

#### Users Page
- Directory of all team members
- User details and assigned tasks
- Activity history

---

## 11. Non-Functional Requirements

### Performance
- Environment setup and teardown: < 10 minutes (target: 5-7 minutes)
- API response time: < 200ms for cached queries
- Database queries: < 100ms
- Frontend page load: < 2 seconds
- Hot reload on code changes: < 500ms

### Security
- Environment variables for sensitive configuration
- PostgreSQL credentials managed via environment variables (not hardcoded)
- Redis runs without authentication in dev environment (expected for local dev)
- CORS headers configured for frontend-to-API communication
- Parameterized queries prevent SQL injection
- XSS protection via React's built-in escaping

### Scalability
- Solution supports future enhancements and additional services
- Easy to add new microservices following same pattern
- Configuration supports multiple replicas
- Database migrations handled automatically on startup

### Reliability
- All services have health checks configured
- Automatic pod restart on failure
- Clear error messages for troubleshooting
- Graceful error handling for common issues

### Compliance
- Adherence to standard software development practices
- Kubernetes best practices for local development
- Docker security best practices
- Git-compatible version control

---

## 12. User Experience & Design Considerations

### Workflow
1. **Clone Repository** - `git clone ...`
2. **Navigate to Directory** - `cd wander-dev-env`
3. **Start Environment** - `make dev`
4. **View Progress** - Real-time feedback and status
5. **Access Application** - Open browser to http://localhost:3000
6. **Explore Demo** - Interact with functional demo application
7. **Start Coding** - Modify code and see hot-reload in action
8. **Cleanup** - `make teardown` when done

### Command-Line Interface Principles
- **Clear Output**: Each command prints what it's doing
- **Progress Indicators**: Show wait times and current operations
- **Error Messages**: Provide actionable guidance when something fails
- **Emoji Usage**: Visual indicators for status (✅, ❌, ⏳, 🚀, etc.)
- **Color Coding**: Success (green), errors (red), warnings (yellow), info (blue)

### Accessibility
- Scripts and documentation accessible to developers with varying expertise levels
- Clear troubleshooting guide for common errors
- No assumptions about prior Kubernetes knowledge
- Detailed logging for debugging
- README with setup prerequisites clearly listed

---

## 13. Dependencies & Assumptions

### Required Dependencies
- **Docker**: Version 20.10+ (or Docker Desktop 4.0+)
- **Kubernetes**: Local cluster via Docker Desktop, Minikube, or Kind
- **kubectl**: Version 1.24+
- **GNU gettext** (envsubst): For template processing
- **make**: GNU Make or compatible
- **Git**: For version control

### Assumptions
- Developers have basic knowledge of command-line operations
- Access to necessary tooling (Docker, Git) pre-installed
- 8GB+ RAM available (for Docker and Kubernetes)
- 10GB+ disk space for images and containers
- Stable internet connection for initial image pulls
- macOS users have Xcode Command Line Tools installed

---


```
wander-dev-env/
├── Makefile                          # Main entry point commands
├── README.md                         # Setup and usage documentation
├── .env.example                      # Environment variable template
├── scripts/
│   ├── wait-for-services.sh         # Health check polling script
│   ├── detect-platform.sh           # OS detection and compatibility
│   └── cleanup.sh                   # Environment cleanup utilities
├── k8s/
│   ├── namespace.yaml               # Kubernetes namespace
│   ├── configmap.yaml               # Configuration values
│   ├── postgres.yaml                # Database deployment
│   ├── redis.yaml                   # Cache deployment
│   ├── api.yaml                     # Backend API deployment
│   └── frontend.yaml                # Frontend deployment
├── services/
│   ├── api/
│   │   ├── Dockerfile               # API container definition
│   │   ├── src/
│   │   │   ├── index.ts            # Express app entry point
│   │   │   ├── routes/              # API endpoints
│   │   │   ├── database/            # Database connection and queries
│   │   │   ├── cache/               # Redis cache utilities
│   │   │   └── middleware/          # Express middleware
│   │   ├── package.json             # Dependencies
│   │   └── tsconfig.json            # TypeScript config
│   ├── frontend/
│   │   ├── Dockerfile               # Frontend container definition
│   │   ├── src/
│   │   │   ├── index.tsx            # React entry point
│   │   │   ├── pages/               # React pages
│   │   │   ├── components/          # Reusable components
│   │   │   ├── api/                 # API client utilities
│   │   │   └── styles/              # Tailwind CSS configuration
│   │   ├── package.json             # Dependencies
│   │   └── tailwind.config.js        # Tailwind configuration
│   └── postgres/
│       ├── Dockerfile               # Database image
│       └── init/
│           └── seed.sql             # Mock data seed script
└── docs/
    ├── ARCHITECTURE.md              # System architecture overview
    ├── API.md                       # API endpoint documentation
    ├── DATABASE.md                  # Database schema documentation
    ├── TROUBLESHOOTING.md           # Common issues and solutions
    └── CONTRIBUTING.md              # Contribution guidelines
```

---

## 15. Setup Command Reference

### Commands Available

| Command | Purpose | Implementation Details |
|---------|---------|------------------------|
| `make dev` | Start entire environment | 1. Run preflight checks<br>2. Copy .env.example to .env if missing<br>3. Create directories (.pids/, infra/generated/)<br>4. Run envsubst on k8s templates<br>5. Build Docker images<br>6. Apply Kubernetes manifests<br>7. Wait for pods to be ready<br>8. Set up port-forwards in background<br>9. Display access URLs |
| `make teardown` | Clean up all resources | 1. Kill port-forward processes (from .pids/)<br>2. Delete namespace wander-dev<br>3. Remove generated files (infra/generated/)<br>4. Remove .pids/ directory<br>5. Keep Docker images for faster restart |
| `make restart` | Restart environment | Shortcut for `make teardown && make dev` |
| `make logs` | Stream real-time logs | Follow logs from all pods in parallel |
| `make logs-api` | Stream API logs only | `kubectl logs -f -n wander-dev -l app=api` |
| `make logs-frontend` | Stream frontend logs only | `kubectl logs -f -n wander-dev -l app=frontend` |
| `make logs-postgres` | Stream postgres logs only | `kubectl logs -f -n wander-dev -l app=postgres` |
| `make logs-redis` | Stream redis logs only | `kubectl logs -f -n wander-dev -l app=redis` |
| `make status` | Check service health | Display pod status: `kubectl get pods -n wander-dev` |
| `make seed-db` | Reseed database | Execute seed.sql inside postgres pod (idempotent) |
| `make test` | Run integration tests | Execute Jest tests with `--runInBand --coverage` |
| `make build` | Build Docker images only | Build without deploying |
| `make clean` | Remove Docker images | Delete built images to force fresh build |
| `make help` | Show available commands | Display command reference with descriptions |

### Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | - |
| API | http://localhost:4000 | - |
| API Health | http://localhost:4000/health | - |
| PostgreSQL | localhost:5432 | user: postgres, password: dev_password |
| Redis | localhost:6379 | - |

---

## 16. Out of Scope

- Advanced CI/CD pipeline integrations
- Production-level secret management systems
- Comprehensive performance benchmarking beyond basic metrics
- Multi-region deployment strategies
- Advanced monitoring and observability solutions (Prometheus, Grafana)
- Mobile app development environment
- Infrastructure-as-Code for production GKE setup

---

## 17. Success Criteria & Acceptance Tests

### Setup & Teardown
- ✅ `make dev` completes successfully in < 7 minutes on modern hardware
- ✅ All services (frontend, API, database, cache) are running and healthy
- ✅ `make teardown` cleanly removes all resources
- ✅ Second run of `make dev` works without conflicts

### Cross-Platform Compatibility
- ✅ Setup works on Windows 10/11 with WSL2
- ✅ Setup works on macOS (Intel and Apple Silicon)
- ✅ Setup works on Linux (Ubuntu/Debian/CentOS/Fedora)
- ✅ No platform-specific manual steps required

### Demo Application
- ✅ Frontend loads successfully at http://localhost:3000
- ✅ Frontend displays teams, projects, and tasks from mock data
- ✅ API endpoints respond with correct mock data
- ✅ Can create, read, update, delete through API
- ✅ Can navigate through all demo pages in frontend
- ✅ Database contains expected seed data after startup

### Logging & Debugging
- ✅ `make logs` streams live logs from all services
- ✅ Real-time feedback during `make dev` shows progress
- ✅ Clear error messages for common issues
- ✅ Service status visible via `make status`

### Configuration & Customization
- ✅ Default `.env` values work out-of-the-box
- ✅ Template variables can be overridden via environment
- ✅ Configuration changes don't require code modifications
- ✅ YAML files clearly documented with variable substitution

---

## 18. Document Sign-Off

This Implementation PRD provides complete technical specifications for building the Zero-to-Running Developer Environment. All implementation decisions have been documented with clear functional and non-functional requirements, mock data specifications, and technical architecture details.

**Ready for development to begin.**
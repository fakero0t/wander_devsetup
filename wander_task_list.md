# Wander Zero-to-Running Developer Environment - Implementation Task List

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

This document breaks down the implementation of the Zero-to-Running Developer Environment PRD into sequential pull requests.

---

## PR #1: Project Setup & Monorepo Structure

**Goal:** Establish the foundational repository structure with npm workspaces, base configurations, and development tooling.

### Files to Create

**Root Level:**
- `package.json` - Root workspace configuration with workspaces array: `["packages/shared", "services/api", "services/frontend"]`
- `package-lock.json` - Will be generated after npm install
- `tsconfig.base.json` - Base TypeScript config extended by all packages:
  - `target: "ES2020"`
  - `module: "ESNext"`
  - `moduleResolution: "node"`
  - `strict: false`
  - `esModuleInterop: true`
  - `skipLibCheck: true`
  - `resolveJsonModule: true`
  - `declaration: true`
  - `sourceMap: true`
- `.eslintrc.json` - ESLint configuration:
  - Extends: `eslint:recommended`, `plugin:@typescript-eslint/recommended`
  - Rules: Allow `any`, console logs, unused vars as warnings
- `jest.config.js` - Jest configuration:
  - Preset: `ts-jest`
  - testEnvironment: `node`
  - roots: `['<rootDir>/tests']`
  - testTimeout: 30000
- `.gitignore` - Ignore: `.env`, `.pids/`, `infra/generated/`, `node_modules`, `dist/`, `coverage`
- `.nvmrc` - Content: `20`
- `.editorconfig` - Standard editor configuration
- `README.md` - Initial setup instructions pointing to docs
- `.env.example` - Template with all environment variables:
  ```
  DATABASE_HOST=postgres
  DATABASE_PORT=5432
  DATABASE_NAME=wander_dev
  DATABASE_USER=postgres
  DATABASE_PASSWORD=dev_password
  DATABASE_POOL_SIZE=10
  API_HOST=0.0.0.0
  API_PORT=4000
  API_DEBUG_PORT=9229
  API_LOG_LEVEL=debug
  NODE_ENV=development
  FRONTEND_HOST=0.0.0.0
  FRONTEND_PORT=3000
  VITE_API_URL=http://localhost:4000
  REDIS_HOST=redis
  REDIS_PORT=6379
  ENVIRONMENT=development
  ```

**VS Code Configuration:**
- `.vscode/settings.json` - Workspace settings (formatOnSave: false, typescript.tsdk, files.eol: "\n")
- `.vscode/launch.json` - Debug configuration for attaching to API on port 9229

**Directory Structure:**
- `scripts/` - Empty directory for future scripts
- `infra/k8s/` - Empty directory for Kubernetes manifests
- `infra/generated/` - Gitignored directory for generated manifests
- `packages/shared/` - Shared package directory
- `services/api/` - API service directory
- `services/frontend/` - Frontend service directory
- `db/init/` - Database initialization scripts directory
- `tests/` - Integration tests directory
- `docs/` - Documentation directory

**Root package.json scripts:**
```json
{
  "scripts": {
    "dev": "npm run dev --workspaces",
    "build": "npm run build --workspaces",
    "test": "jest --runInBand --coverage"
  }
}
```

**Dependencies to install at root:**
- jest: ^29.7.0
- @types/jest: ^29.5.0
- ts-jest: ^29.1.0

### Acceptance Criteria
- `npm install` runs successfully
- All workspaces are recognized
- ESLint runs without errors
- Directory structure matches PRD specification
- `.nvmrc` specifies Node 20

---

## PR #2: Shared Package Implementation

**Goal:** Create the shared package with all TypeScript types, constants, and utility functions used by both API and Frontend.

### Files to Create

**packages/shared/package.json:**
```json
{
  "name": "@wander/shared",
  "version": "1.0.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch"
  },
  "devDependencies": {
    "typescript": "^5.3.0"
  }
}
```

**packages/shared/tsconfig.json:**
- Extends `../../tsconfig.base.json`
- `outDir: "./dist"`
- `rootDir: "./src"`
- Include: `["src/**/*"]`
- Exclude: `["node_modules", "dist"]`

**packages/shared/src/index.ts:**
- Export all types and constants

**packages/shared/src/types/user.ts:**
```typescript
export interface User {
  id: number;
  name: string;
  email: string;
  created_at: string;
  updated_at: string;
}
```

**packages/shared/src/types/team.ts:**
```typescript
export interface Team {
  id: number;
  name: string;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface TeamMember {
  id: number;
  team_id: number;
  user_id: number;
  joined_at: string;
}
```

**packages/shared/src/types/project.ts:**
```typescript
export enum ProjectStatus {
  Planning = 'planning',
  Active = 'active',
  Completed = 'completed'
}

export interface Project {
  id: number;
  team_id: number;
  name: string;
  description: string | null;
  status: ProjectStatus;
  created_at: string;
  updated_at: string;
}
```

**packages/shared/src/types/task.ts:**
```typescript
export enum TaskStatus {
  Todo = 'todo',
  InProgress = 'in_progress',
  Done = 'done'
}

export enum TaskPriority {
  Low = 'low',
  Medium = 'medium',
  High = 'high'
}

export interface Task {
  id: number;
  project_id: number;
  assigned_to: number | null;
  title: string;
  description: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  created_at: string;
  updated_at: string;
}
```

**packages/shared/src/types/activity.ts:**
```typescript
export interface Activity {
  id: number;
  user_id: number;
  action: string;
  entity_type: string | null;
  entity_id: number | null;
  description: string | null;
  created_at: string;
}
```

**packages/shared/src/constants/index.ts:**
- Export status/priority enums as constants for validation

### Acceptance Criteria
- `npm run build` in shared package compiles successfully
- `dist/` folder contains compiled JavaScript and type declarations
- All types match database schema from PRD
- Enums match canonical values from PRD (todo/in_progress/done, low/medium/high)

---

## PR #3: Database & Seed Script

**Goal:** Create PostgreSQL Docker image with initialization scripts and comprehensive seed data.

### Files to Create

**db/Dockerfile:**
```dockerfile
FROM postgres:14-alpine

# Copy seed script to initialization directory
COPY init/seed.sql /docker-entrypoint-initdb.d/seed.sql

# Environment variables will be passed at runtime
ENV POSTGRES_DB=wander_dev
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=dev_password

EXPOSE 5432

# Healthcheck
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD pg_isready -U postgres -d wander_dev || exit 1
```

**db/init/seed.sql:**
Complete PL/pgSQL script implementing:
1. Idempotency check (check user count, return if > 0)
2. DROP TABLE IF EXISTS for all tables (CASCADE)
3. CREATE TABLE statements for all 6 tables:
   - `users` (id SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255) UNIQUE, created_at, updated_at)
   - `teams` (id SERIAL, name VARCHAR(255), description TEXT, created_at, updated_at)
   - `team_members` (id SERIAL, team_id INT REFERENCES teams ON DELETE CASCADE ON UPDATE CASCADE, user_id INT REFERENCES users ON DELETE CASCADE ON UPDATE CASCADE, joined_at, UNIQUE(team_id, user_id))
   - `projects` (id SERIAL, team_id INT REFERENCES teams ON DELETE CASCADE ON UPDATE CASCADE, name VARCHAR(255), description TEXT, status VARCHAR(50) DEFAULT 'active', created_at, updated_at)
   - `tasks` (id SERIAL, project_id INT REFERENCES projects ON DELETE CASCADE ON UPDATE CASCADE, assigned_to INT REFERENCES users ON DELETE SET NULL, title VARCHAR(255), description TEXT, status VARCHAR(50) DEFAULT 'todo', priority VARCHAR(50) DEFAULT 'medium', created_at, updated_at)
   - `activities` (id SERIAL, user_id INT REFERENCES users ON DELETE CASCADE, action VARCHAR(100), entity_type VARCHAR(100), entity_id INT, description TEXT, created_at)
4. CREATE INDEX statements:
   - idx_users_email ON users(email)
   - idx_team_members_user_id, idx_team_members_team_id
   - idx_projects_team_id
   - idx_tasks_project_id, idx_tasks_assigned_to, idx_tasks_status
   - idx_activities_user_id, idx_activities_created_at
5. INSERT statements for seed data:
   - **5 users:** 
     - Alice Chen (alice@wander.com) - Frontend Lead
     - Bob Martinez (bob@wander.com) - Backend Lead
     - Carol Singh (carol@wander.com) - Full Stack
     - David Lee (david@wander.com) - DevOps
     - Emma Johnson (emma@wander.com) - Frontend Developer
   - **2 teams:** 
     - Frontend Squad (description: "Building amazing user interfaces")
     - Backend Brigade (description: "Powering the backend infrastructure")
   - **5 team_members entries:**
     - Alice → Frontend Squad
     - Emma → Frontend Squad
     - Carol → Frontend Squad
     - Bob → Backend Brigade
     - David → Backend Brigade
   - **2 projects:** 
     - Dashboard Redesign (Frontend Squad, active, "Modernize the main dashboard UI with new design system")
     - API v2 Migration (Backend Brigade, active, "Migrate from REST to GraphQL with improved performance")
   - **6 tasks with specific details:**
     - "Design new dashboard layout" (Dashboard Redesign, assigned to Alice, in_progress, high)
     - "Implement responsive grid system" (Dashboard Redesign, assigned to Emma, todo, medium)
     - "Add dark mode support" (Dashboard Redesign, unassigned, todo, low)
     - "Design GraphQL schema" (API v2 Migration, assigned to Bob, done, high)
     - "Implement resolvers" (API v2 Migration, assigned to Bob, in_progress, high)
     - "Write migration scripts" (API v2 Migration, assigned to David, todo, medium)
   - **10 activities:** Sample entries like:
     - "Alice Chen created task: Design new dashboard layout"
     - "Bob Martinez completed task: Design GraphQL schema"
     - "Emma Johnson joined team Frontend Squad"
     - Realistic timestamps spread across last 7 days
6. RAISE NOTICE with success message: "Database seeded successfully: 5 users, 2 teams, 2 projects, 6 tasks, 10 activities"

### Acceptance Criteria
- Seed script runs without errors in PostgreSQL 14
- Idempotency works (running twice doesn't duplicate data)
- All foreign key constraints work correctly
- Exactly 5 users, 2 teams, 2 projects, 6 tasks, 10 activities
- All timestamps in UTC
- Indexes created successfully

---

## PR #4: API Service Implementation

**Goal:** Implement the complete Express.js API with all routes, database connectivity, Redis caching, and health checks.

### Files to Create

**services/api/package.json:**
```json
{
  "name": "@wander/api",
  "version": "1.0.0",
  "scripts": {
    "dev": "nodemon",
    "build": "tsc",
    "start": "node dist/index.js"
  },
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

**services/api/tsconfig.json:**
- Extends `../../tsconfig.base.json`
- Path aliases: `@/routes/*`, `@/database/*`, `@/cache/*`, `@/middleware/*`, `@/types/*`
- outDir: `./dist`, rootDir: `./src`, baseUrl: `./src`

**services/api/nodemon.json:**
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

**services/api/.dockerignore:**
- node_modules, dist, .env, *.md

**services/api/Dockerfile:**
```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /workspace
# Copy workspace configuration
COPY package*.json tsconfig.base.json ./
COPY packages/shared ./packages/shared
COPY services/api ./services/api
# Install all dependencies including dev dependencies
RUN npm ci --workspaces
# Build shared package first
RUN npm run build --workspace=packages/shared
# Build API
RUN npm run build --workspace=services/api

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app
# Copy package files and install production dependencies only
COPY package*.json ./
COPY services/api/package.json ./services/api/
RUN npm ci --workspace=services/api --only=production
# Copy built artifacts
COPY --from=builder /workspace/packages/shared/dist ./packages/shared/dist
COPY --from=builder /workspace/services/api/dist ./services/api/dist
# Set working directory to API
WORKDIR /app/services/api
# Expose ports
EXPOSE 4000 9229
# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s \
  CMD node -e "require('http').get('http://localhost:4000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"
# Start command
CMD ["node", "dist/index.js"]
```

**services/api/src/index.ts:**
- Import dotenv/config at top
- Import database connection and run migrations
- Import Redis client setup
- Import Express app
- Graceful shutdown handler for SIGTERM
- Start server on port from env (default 4000)

**services/api/src/database/connection.ts:**
- Knex configuration object matching PRD specification
- Export configured knex instance
- Run `knex.migrate.latest()` on startup with try/catch

**services/api/src/cache/redis.ts:**
- ioredis client setup with host/port from env
- Retry strategy: exponential backoff, max 3 retries
- Graceful degradation: export helper functions that try/catch and continue on error
- Export caching helpers: `getCached()`, `setCached()`, `deleteCached()`

**services/api/src/middleware/logging.ts:**
- Request logging middleware
- Format: `[timestamp] METHOD /path STATUS (duration)`
- Use pino for structured logging in production, simple console in dev

**services/api/src/routes/health.ts:**
- `GET /health` - Simple liveness check, returns `{ status: "ok" }`
- `GET /health/ready` - Readiness check with DB SELECT 1 and Redis PING, returns `{ status: "ok", timestamp, services: { db: "connected", redis: "connected" } }`

**services/api/src/routes/users.ts:**
- `GET /users` - List with limit/offset pagination:
  - Query: `SELECT * FROM users ORDER BY id LIMIT ? OFFSET ?`
  - Default limit: 10, default offset: 0
  - Return array directly (no wrapper)
- `GET /users/:id` - Get single user:
  - Query: `SELECT * FROM users WHERE id = ?`
  - Return 404 with `{ message: "User not found" }` if not exists
- `POST /users` - Create user:
  - Validate: name and email required
  - Check: email unique (catch constraint error)
  - Query: `INSERT INTO users (name, email) VALUES (?, ?) RETURNING *`
  - Return created user object with 201 status
- `PUT /users/:id` - Update user:
  - Full replacement (name, email required)
  - Query: `UPDATE users SET name = ?, email = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? RETURNING *`
  - Return updated user object
- `DELETE /users/:id` - Delete user:
  - Query: `DELETE FROM users WHERE id = ?`
  - Return 204 No Content (empty body)

**services/api/src/routes/teams.ts:**
- `GET /teams` - List all teams
- `GET /teams/:id` - Get team with members (JOIN team_members, users)
- `POST /teams` - Create team
- `POST /teams/:id/members` - Add user to team (insert into team_members)
- `DELETE /teams/:id/members/:userId` - Remove user from team

**services/api/src/routes/projects.ts:**
- `GET /projects` - List all projects
- `GET /projects/:id` - Get project with tasks
- `POST /projects` - Create project
- `PUT /projects/:id` - Update project
- `DELETE /projects/:id` - Delete project

**services/api/src/routes/tasks.ts:**
- `GET /tasks` - List all tasks with pagination
- `GET /tasks/:id` - Get single task
- `POST /tasks` - Create task
- `PUT /tasks/:id` - Update task (including status, priority, assigned_to)
- `DELETE /tasks/:id` - Delete task
- `GET /tasks/assigned/:userId` - Get tasks assigned to user

**services/api/src/routes/activities.ts:**
- `GET /activities` - List recent activities:
  - Cache key: `cache:activities:all`
  - TTL: 3600 seconds (1 hour)
  - Query: `SELECT a.*, u.name as user_name FROM activities a JOIN users u ON a.user_id = u.id ORDER BY created_at DESC LIMIT 50`
  - Check cache first, if miss query DB and cache result
  - Return array directly
- `GET /activities/user/:userId` - Activities by specific user:
  - Cache key: `cache:activities:user:{userId}`
  - TTL: 3600 seconds
  - Query: `SELECT * FROM activities WHERE user_id = ? ORDER BY created_at DESC`
  - Check cache first, if miss query DB and cache result
- Helper function `createActivity(userId, action, entityType, entityId, description)`:
  - Insert new activity
  - Invalidate cache: delete keys `cache:activities:all` and `cache:activities:user:{userId}`
  - Return created activity object

**services/api/src/server.ts:**
- Express app setup
- CORS configuration: origin `http://localhost:3000`, credentials: true, methods: GET/POST/PUT/DELETE
- Middleware: `express.json({ limit: '10mb' })`, logging middleware
- Route mounting: `/api/users`, `/api/teams`, `/api/projects`, `/api/tasks`, `/api/activities`, `/health`
- Error handler: return `{ message }` with 500 status

### Acceptance Criteria
- All endpoints return correct response formats (arrays for lists, objects for single, 204 for delete)
- Knex migrations run automatically on startup
- Redis caching works with graceful degradation
- Health endpoints return correct status
- CORS configured correctly
- Hot reload works with nodemon
- TypeScript compiles without errors

---

## PR #5: Frontend Application Implementation

**Goal:** Build the complete React frontend with all pages, components, routing, and API integration.

### Files to Create

**services/frontend/package.json:**
```json
{
  "name": "@wander/frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
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

**services/frontend/tsconfig.json:**
- Extends `../../tsconfig.base.json`
- jsx: `react-jsx`
- Path aliases: `@/pages/*`, `@/components/*`, `@/api/*`, `@/types/*`

**services/frontend/vite.config.ts:**
Full configuration from PRD:
- React plugin
- server: port 3000, host 0.0.0.0
- resolve alias: `@` → `./src`
- build: sourcemap true, chunkSizeWarningLimit 1000

**services/frontend/tailwind.config.js:**
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

**services/frontend/postcss.config.js:**
```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {}
  }
};
```

**services/frontend/.dockerignore:**
- node_modules, dist, .env

**services/frontend/Dockerfile:**
```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /workspace
# Copy workspace configuration
COPY package*.json tsconfig.base.json ./
COPY packages/shared ./packages/shared
COPY services/frontend ./services/frontend
# Install dependencies
RUN npm ci --workspaces
# Build shared package first
RUN npm run build --workspace=packages/shared
# Build frontend
RUN npm run build --workspace=services/frontend

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app
# Install serve globally
RUN npm install -g serve@14.2.0
# Copy built frontend
COPY --from=builder /workspace/services/frontend/dist ./dist
# Expose port
EXPOSE 3000
# Health check
HEALTHCHECK --interval=30s --timeout=5s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1
# Serve static files with SPA fallback
CMD ["serve", "-s", "dist", "-l", "3000", "--no-clipboard"]
```

**services/frontend/index.html:**
- Standard HTML5 with `<div id="root"></div>`
- Link to Vite entry point

**services/frontend/.env.example:**
```
VITE_API_URL=http://localhost:4000
```

**services/frontend/src/main.tsx:**
- React 18 createRoot
- Import App component
- Import tailwind.css

**services/frontend/src/styles/tailwind.css:**
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**services/frontend/src/App.tsx:**
- BrowserRouter setup
- Routes for: `/`, `/teams`, `/projects`, `/projects/:id`, `/users`, catch-all 404
- Layout with Header, Nav, main content area, Footer

**services/frontend/src/api/client.ts:**
API client with typed functions:
```typescript
const API_BASE = import.meta.env.VITE_API_URL;

export async function apiGet<T>(path: string): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);
  const res = await fetch(`${API_BASE}${path}`, { signal: controller.signal });
  clearTimeout(timeout);
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

// Similar for apiPost, apiPut, apiDelete
```

**services/frontend/src/components/Header.tsx:**
- App title, simple header with Tailwind styling

**services/frontend/src/components/Nav.tsx:**
- Navigation links to all pages
- Use react-router-dom Link component

**services/frontend/src/components/Footer.tsx:**
- Simple footer with copyright

**services/frontend/src/components/Modal.tsx:**
- Custom modal using React Portal
- Props: isOpen, onClose, children
- Overlay with click-outside-to-close
- Tailwind styled centered card

**services/frontend/src/components/ModalHeader.tsx, ModalBody.tsx, ModalFooter.tsx:**
- Subcomponents for modal structure

**services/frontend/src/pages/Dashboard.tsx:**
```typescript
import { useState, useEffect } from 'react';
import { apiGet } from '@/api/client';
import { Activity } from '@wander/shared';

export function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [activities, setActivities] = useState<Activity[]>([]);

  useEffect(() => {
    apiGet<Activity[]>('/api/activities')
      .then(setActivities)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="text-center p-8">Loading...</div>;

  if (activities.length === 0) {
    return (
      <div className="text-center p-8 text-gray-500">
        No recent activity. Create a task to get started!
      </div>
    );
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
      <div className="space-y-2">
        {activities.map(activity => (
          <div key={activity.id} className="bg-white p-4 rounded shadow">
            <p>{activity.description}</p>
            <p className="text-sm text-gray-500">
              {new Intl.DateTimeFormat('en-US', { 
                dateStyle: 'medium', 
                timeStyle: 'short' 
              }).format(new Date(activity.created_at))}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
```

**services/frontend/src/pages/Teams.tsx:**
- Fetch teams on mount
- Display team list with member count
- Links to team projects
- Empty state: "No teams yet."

**services/frontend/src/pages/Projects.tsx:**
- Fetch projects on mount
- Display project list grouped by team
- Project status indicators
- Links to project detail pages
- Modal for creating new project
- Empty state: "No projects yet. Create one to begin."

**services/frontend/src/pages/ProjectDetail.tsx:**
- Fetch project and tasks by ID from route params
- Display project info
- Task list with status indicators
- Modal for creating/editing tasks
- Empty state for tasks: "No tasks in this project."

**services/frontend/src/pages/Users.tsx:**
- Fetch users on mount
- Display user directory
- Show assigned task count per user
- Links to user activity

**All pages implement:**
- useState for data and loading
- useEffect for data fetching on mount
- Error display in modal if fetch fails
- Controlled form inputs with validation (HTML5 required, type="email")
- Submit button disabled during submission
- Success = close modal, error = show in modal
- Date display using `Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeStyle: 'short' })`

### Acceptance Criteria
- All pages render without errors
- Routing works with clean URLs (BrowserRouter)
- API integration functions correctly
- Forms submit data successfully
- Modal dialogs open and close properly
- Empty states display correctly
- Loading states show during fetch
- Tailwind styles applied correctly
- Hot module replacement works

---

## PR #6: Kubernetes Manifests

**Goal:** Create all Kubernetes YAML manifests for deploying services to local cluster.

### Files to Create

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

### Acceptance Criteria
- All manifests are valid YAML
- Template variables clearly marked
- Resource limits match PRD specifications
- Health check timing matches PRD specifications
- All services use ClusterIP
- Namespace is wander-dev

---

## PR #7: Makefile & Automation Scripts

**Goal:** Create the complete Makefile and all helper scripts for deployment, monitoring, and management.

### Files to Create

**Makefile:**
```makefile
.PHONY: help dev teardown restart build logs logs-api logs-frontend logs-postgres logs-redis status seed-db test shell-api db-shell clean

# Include .env file if it exists
-include .env
export

NAMESPACE := wander-dev
WORKSPACE_PATH := $(shell pwd)

help: ## Display this help message
	@echo "Wander Developer Environment - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-15s\033[0m %s\n", $$1, $$2}'

dev: ## Start the entire development environment
	@./scripts/preflight-check.sh
	@[ -f .env ] || cp .env.example .env
	@mkdir -p .pids infra/generated
	@export WORKSPACE_PATH=$(WORKSPACE_PATH) && ./scripts/prepare-manifests.sh
	@echo "🔨 Building Docker images..."
	@docker build -t wander-api:latest -f services/api/Dockerfile .
	@docker build -t wander-frontend:latest -f services/frontend/Dockerfile .
	@echo "🎯 Applying Kubernetes manifests..."
	@kubectl apply -f infra/generated/namespace.yaml
	@kubectl apply -f infra/generated/configmap.yaml
	@kubectl apply -f infra/generated/postgres.yaml
	@kubectl apply -f infra/generated/redis.yaml
	@kubectl apply -f infra/generated/api.yaml
	@kubectl apply -f infra/generated/frontend.yaml
	@./scripts/wait-for-services.sh
	@echo "🔌 Setting up port forwards..."
	@kubectl port-forward -n $(NAMESPACE) svc/frontend 3000:3000 > /dev/null 2>&1 & echo $$! > .pids/frontend.pid
	@kubectl port-forward -n $(NAMESPACE) svc/api 4000:4000 > /dev/null 2>&1 & echo $$! > .pids/api.pid
	@kubectl port-forward -n $(NAMESPACE) svc/postgres 5432:5432 > /dev/null 2>&1 & echo $$! > .pids/postgres.pid
	@kubectl port-forward -n $(NAMESPACE) svc/redis 6379:6379 > /dev/null 2>&1 & echo $$! > .pids/redis.pid
	@sleep 2
	@echo "✅ Environment is ready!"
	@echo "📝 Access your environment:"
	@echo "   Frontend:  http://localhost:3000"
	@echo "   API:       http://localhost:4000"
	@echo "   API Health: http://localhost:4000/health"

teardown: ## Stop and clean up the entire environment
	@echo "🧹 Cleaning up environment..."
	@if [ -d .pids ]; then \
		for pid_file in .pids/*.pid; do \
			[ -f "$$pid_file" ] && kill $$(cat "$$pid_file") 2>/dev/null || true; \
		done; \
		rm -rf .pids; \
	fi
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	@rm -rf infra/generated
	@echo "✅ Environment cleaned up"

restart: teardown dev ## Restart the environment (teardown + dev)

build: ## Build Docker images only
	@echo "🔨 Building Docker images..."
	@docker build -t wander-api:latest -f services/api/Dockerfile .
	@docker build -t wander-frontend:latest -f services/frontend/Dockerfile .
	@echo "✅ Images built successfully"

logs: ## Stream logs from all pods
	@kubectl logs -f -n $(NAMESPACE) -l app=api & \
	kubectl logs -f -n $(NAMESPACE) -l app=frontend & \
	kubectl logs -f -n $(NAMESPACE) -l app=postgres & \
	kubectl logs -f -n $(NAMESPACE) -l app=redis & \
	wait

logs-api: ## Stream logs from API pod only
	@kubectl logs -f -n $(NAMESPACE) -l app=api

logs-frontend: ## Stream logs from frontend pod only
	@kubectl logs -f -n $(NAMESPACE) -l app=frontend

logs-postgres: ## Stream logs from postgres pod only
	@kubectl logs -f -n $(NAMESPACE) -l app=postgres

logs-redis: ## Stream logs from redis pod only
	@kubectl logs -f -n $(NAMESPACE) -l app=redis

status: ## Check status of all pods
	@kubectl get pods -n $(NAMESPACE)

seed-db: ## Manually reseed the database
	@kubectl exec -n $(NAMESPACE) deployment/postgres -- psql -U postgres -d wander_dev -f /docker-entrypoint-initdb.d/seed.sql

test: ## Run integration tests
	@npm test

shell-api: ## Open shell in API pod
	@kubectl exec -it -n $(NAMESPACE) deployment/api -- sh

db-shell: ## Open psql shell in database pod
	@kubectl exec -it -n $(NAMESPACE) deployment/postgres -- psql -U postgres -d wander_dev

clean: ## Remove all Docker images
	@docker rmi wander-api:latest wander-frontend:latest 2>/dev/null || true
	@echo "✅ Docker images removed"
```

**scripts/preflight-check.sh:**
```bash
#!/bin/bash
set -e

echo "🚀 Starting Zero-to-Running Developer Environment..."

# Detect OS
OS=$(uname -s)
echo "📋 Platform: $OS"

# Check Docker
echo -n "Checking Docker... "
if ! command -v docker &> /dev/null || ! docker ps &> /dev/null; then
  echo "❌ Docker is not running. Start Docker Desktop and try again."
  exit 1
fi
echo "✅"

# Check kubectl
echo -n "Checking kubectl... "
if ! command -v kubectl &> /dev/null; then
  echo "❌ kubectl not found. Install kubectl and try again."
  exit 1
fi
if ! kubectl cluster-info &> /dev/null; then
  echo "❌ Kubernetes not configured. Enable in Docker Desktop or install Minikube."
  exit 1
fi
echo "✅"

# Check envsubst
echo -n "Checking envsubst... "
if ! command -v envsubst &> /dev/null; then
  echo "❌ envsubst not found. Install gettext package."
  exit 1
fi
echo "✅"

# Check make
echo -n "Checking make... "
if ! command -v make &> /dev/null; then
  echo "❌ make not found. Install make and try again."
  exit 1
fi
echo "✅"

# Check disk space
DISK_AVAIL=$(df -k . | awk 'NR==2 {print $4}')
if [ "$DISK_AVAIL" -lt 10485760 ]; then
  echo "⚠️  Warning: Less than 10GB disk space available"
fi

# Check memory (macOS vs Linux)
if [ "$OS" = "Darwin" ]; then
  MEM_TOTAL=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024}')
else
  MEM_TOTAL=$(free -g | awk 'NR==2 {print $2}')
fi
if [ "${MEM_TOTAL%.*}" -lt 4 ]; then
  echo "⚠️  Warning: Less than 4GB RAM available"
fi

# Check ports
for PORT in 3000 4000 5432 6379; do
  if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -an | grep -q ":$PORT.*LISTEN" 2>/dev/null; then
    echo "❌ Port $PORT is already in use. Stop the process or change ${PORT}_PORT in .env"
    exit 1
  fi
done

echo "✅ All preflight checks passed"
exit 0
```

**scripts/wait-for-services.sh:**
```bash
#!/bin/bash
set -e

NAMESPACE="wander-dev"
MAX_ATTEMPTS=60
INTERVAL=5

echo "⏳ Waiting for all services to be healthy..."

wait_for_pod() {
  local SERVICE=$1
  local ATTEMPTS=0
  
  echo "  ⏳ $SERVICE: starting..."
  
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    if kubectl get pods -n $NAMESPACE -l app=$SERVICE 2>/dev/null | grep -q "Running"; then
      if kubectl exec -n $NAMESPACE deployment/$SERVICE -- curl -f http://localhost:${2:-4000}/health/ready &>/dev/null 2>&1; then
        echo "  ✅ $SERVICE: ready"
        return 0
      fi
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    sleep $INTERVAL
  done
  
  echo "  ❌ $SERVICE: failed to start"
  kubectl logs -n $NAMESPACE -l app=$SERVICE --tail=50
  return 1
}

# Wait for postgres
wait_for_pod postgres 5432 &
PG_PID=$!

# Wait for redis
wait_for_pod redis 6379 &
REDIS_PID=$!

# Wait for database services first
wait $PG_PID || exit 1
wait $REDIS_PID || exit 1

# Now wait for application services
wait_for_pod api 4000 &
API_PID=$!

wait_for_pod frontend 3000 &
FRONTEND_PID=$!

# Wait for all
wait $API_PID || exit 1
wait $FRONTEND_PID || exit 1

echo "✅ All services are healthy!"
exit 0
```

**scripts/handle-error.sh:**
- Common error handling utilities
- Functions for displaying formatted error messages
- Suggestions based on error type

**scripts/validate-seed.sh:**
- Query database for row counts
- Verify 5 users, 2 teams, 2 projects, 6 tasks, 10 activities
- Log success or warning

**scripts/prepare-manifests.sh:**
```bash
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
  export DEV_FRONTEND_VOLUME=$(cat <<EOF
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
  export FRONTEND_COMMAND='["npm", "run", "dev"]'
else
  # Production: no volumes, use production commands
  export DEV_API_VOLUME=""
  export DEV_FRONTEND_VOLUME=""
  export API_COMMAND='["npm", "start"]'
  export FRONTEND_COMMAND='["serve", "-s", "dist", "-l", "3000", "--no-clipboard"]'
fi

# Process all YAML files
for file in infra/k8s/*.yaml; do
  filename=$(basename "$file")
  envsubst < "$file" > "infra/generated/$filename"
  echo "  ✅ Generated infra/generated/$filename"
done

echo "✅ Manifests prepared successfully"
```

### Acceptance Criteria
- `make help` displays all commands
- `make dev` runs complete startup sequence
- Preflight checks catch missing prerequisites
- Port-forwards run in background with PIDs saved
- `make teardown` cleans up completely
- `make logs` streams from all pods
- Scripts are POSIX-compatible
- Error messages are clear and actionable
- All scripts have proper error handling

---

## PR #8: Integration Tests

**Goal:** Create Jest integration tests that verify the entire system works end-to-end.

### Files to Create

**tests/integration.test.ts:**
Complete test suite:

```typescript
import { describe, test, expect, beforeAll } from '@jest/globals';

const API_BASE = 'http://localhost:4000';

describe('Health Checks', () => {
  test('GET /health returns ok', async () => {
    const res = await fetch(`${API_BASE}/health`);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.status).toBe('ok');
  });

  test('GET /health/ready returns ok with services', async () => {
    const res = await fetch(`${API_BASE}/health/ready`);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.status).toBe('ok');
    expect(data.services.db).toBe('connected');
    expect(data.services.redis).toBe('connected');
  });
});

describe('Users API', () => {
  test('GET /api/users returns array', async () => {
    const res = await fetch(`${API_BASE}/api/users`);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(5);
  });

  test('GET /api/users/1 returns user object', async () => {
    const res = await fetch(`${API_BASE}/api/users/1`);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data).toHaveProperty('id');
    expect(data).toHaveProperty('email');
    expect(data.email).toContain('@wander.com');
  });
});

describe('Teams API', () => {
  test('GET /api/teams returns array', async () => {
    const res = await fetch(`${API_BASE}/api/teams`);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(2);
  });
});

describe('Projects API', () => {
  test('GET /api/projects returns array', async () => {
    const res = await fetch(`${API_BASE}/api/projects`);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(2);
  });
});

describe('Tasks API', () => {
  test('GET /api/tasks returns array', async () => {
    const res = await fetch(`${API_BASE}/api/tasks`);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBeGreaterThan(0);
  });
});

describe('Activities API', () => {
  test('GET /api/activities returns array', async () => {
    const res = await fetch(`${API_BASE}/api/activities`);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBe(10);
  });
});

describe('Pagination', () => {
  test('GET /api/users?limit=2 returns 2 users', async () => {
    const res = await fetch(`${API_BASE}/api/users?limit=2`);
    const data = await res.json();
    expect(data.length).toBe(2);
  });

  test('GET /api/users?offset=10 returns empty array', async () => {
    const res = await fetch(`${API_BASE}/api/users?offset=10`);
    const data = await res.json();
    expect(data.length).toBe(0);
  });
});
```

**tests/fixtures/README.md:**
- Explanation that tests use live seed data
- No fixtures needed

### Acceptance Criteria
- All tests pass against running environment
- Tests cover all major endpoints
- Health checks verify DB and Redis connectivity
- Pagination tests verify correct behavior
- Tests run in serial with `--runInBand`
- Coverage report generated

---

## PR #9: Documentation

**Goal:** Create comprehensive documentation for setup, architecture, API reference, troubleshooting, and contribution guidelines.

### Files to Create

**docs/SETUP.md:**
- Prerequisites with installation links
- Step-by-step setup guide
- Verification steps
- Common first-run issues

**docs/ARCHITECTURE.md:**
- System overview diagram (ASCII or Mermaid)
- Service communication flows
- Database schema diagram
- Kubernetes architecture explanation
- Technology stack rationale
- Design decisions

**docs/API.md:**
- Complete API endpoint reference
- Request/response examples using curl
- All endpoints from PRD with examples
- Error response formats
- Pagination documentation

**docs/DATABASE.md:**
- Complete schema documentation
- Entity relationship diagram
- Table definitions with column types
- Index documentation
- Foreign key relationships
- Seed data explanation

**docs/KUBERNETES.md:**
- Kubernetes concepts for developers
- Service discovery explanation
- Health probes documentation
- Resource limits rationale
- Development vs production configuration

**docs/TROUBLESHOOTING.md:**
- Common error scenarios table from PRD
- Port conflict resolution
- Docker daemon issues
- Kubernetes cluster issues
- Service startup failures
- Database connection issues
- Seed script failures
- Log investigation steps

**docs/CONTRIBUTING.md:**
- Development workflow
- Branch strategy (single main)
- Commit message guidelines (freeform)
- Code style (ESLint rules)
- Testing guidelines
- PR checklist

**docs/images/README.md:**
- Placeholder for future diagrams

**Update root README.md:**
- Project overview
- Quick start (just the commands)
- Link to docs/SETUP.md for details
- Link to docs/API.md for API reference
- Link to docs/TROUBLESHOOTING.md
- Architecture overview with link to docs/ARCHITECTURE.md
- Command reference table from PRD
- Access points table
- Technology stack
- Contributing link

### Acceptance Criteria
- All documentation is comprehensive and accurate
- Links between docs work correctly
- API examples are copy-pasteable
- Troubleshooting covers all common errors from PRD
- README provides clear overview and quick start
- All markdown is properly formatted

---

## PR #10: Final Integration & Validation

**Goal:** Verify complete system integration, add final polish, and ensure all acceptance criteria are met.

### Tasks

**Validation Checklist:**
1. Run `make dev` from scratch on clean machine
2. Verify all services start within 7 minutes
3. Verify frontend loads at http://localhost:3000
4. Verify API responds at http://localhost:4000
5. Test all CRUD operations through UI
6. Verify seed data loads correctly (5 users, 2 teams, 2 projects, 6 tasks, 10 activities)
7. Test `make teardown` and verify clean removal
8. Run `make dev` again to verify repeatability
9. Run `make test` and verify all tests pass
10. Verify hot reload works for both API and frontend
11. Test `make logs` and individual log commands
12. Verify `make status` shows correct pod states
13. Test on macOS (Intel and Apple Silicon if available)
14. Test on Linux
15. Test on Windows WSL2 if available

**Final Polish:**
- Add `.dockerignore` files to all services
- Verify all console logs have proper formatting
- Ensure all error messages are user-friendly
- Check all emoji indicators display correctly
- Verify color coding in terminal output
- Ensure all timestamps display correctly with Intl.DateTimeFormat
- Test empty states in UI
- Test loading states in UI
- Test error states in UI
- Verify modal dialogs work correctly
- Test form validation

**Create additional files if needed:**
- `CHANGELOG.md` - Document initial release
- `LICENSE` - Add appropriate license if required

**Final verification against PRD Success Criteria:**
- ✅ `make dev` completes successfully in < 7 minutes
- ✅ All services running and healthy
- ✅ `make teardown` cleanly removes all resources
- ✅ Second run of `make dev` works without conflicts
- ✅ Cross-platform compatibility verified
- ✅ Frontend loads at http://localhost:3000
- ✅ Frontend displays correct seed data
- ✅ API endpoints respond with correct data
- ✅ CRUD operations work through API
- ✅ Can navigate all demo pages
- ✅ Database contains expected seed data
- ✅ `make logs` streams live logs
- ✅ Real-time feedback during `make dev`
- ✅ Clear error messages for common issues
- ✅ Service status visible via `make status`
- ✅ Default `.env` values work out-of-the-box
- ✅ YAML files documented with variable substitution

### Acceptance Criteria
- Complete system works end-to-end
- All PRD success criteria met
- All acceptance tests pass
- Documentation is complete and accurate
- System tested on multiple platforms
- No known bugs or issues
- Ready for production use as development environment

---

## Implementation Notes

### Sequential Order
These PRs must be implemented in order as each builds on the previous:
1. Project structure must exist before packages
2. Shared types must exist before API and Frontend can import them
3. Database must be ready before API can connect
4. API must be complete before Frontend can integrate
5. Kubernetes manifests needed before automation
6. Automation needed before testing
7. Testing validates everything works
8. Documentation explains how it all works
9. Final validation ensures quality

### Estimated Timeline
- PR #1: 4 hours (project setup)
- PR #2: 4 hours (shared types)
- PR #3: 6 hours (database & seed script)
- PR #4: 16 hours (complete API with all routes)
- PR #5: 16 hours (complete frontend with all pages)
- PR #6: 8 hours (Kubernetes manifests)
- PR #7: 12 hours (Makefile & scripts)
- PR #8: 6 hours (integration tests)
- PR #9: 8 hours (documentation)
- PR #10: 8 hours (final validation)

**Total: ~88 hours of development time**

### Review Focus Areas
- **PR #1-2:** TypeScript configuration, workspace setup
- **PR #3:** SQL correctness, data integrity, idempotency
- **PR #4:** API design, error handling, database queries, Redis integration
- **PR #5:** React patterns, UX, API integration, styling
- **PR #6:** Kubernetes best practices, resource limits, health checks
- **PR #7:** Script robustness, error handling, cross-platform compatibility
- **PR #8:** Test coverage, assertions
- **PR #9:** Documentation clarity, accuracy
- **PR #10:** Overall system quality, acceptance criteria

---

## Additional Implementation Details Included

This task list has been enhanced with comprehensive implementation details from the PRD:

### Code-Level Specifications Added:
1. **Complete Dockerfiles** - Multi-stage builds with exact commands and healthchecks
2. **Full Makefile** - All targets implemented with actual bash commands and error handling
3. **Bash Scripts** - Complete implementations of preflight-check.sh, wait-for-services.sh, and prepare-manifests.sh
4. **API Route Details** - Exact SQL queries, cache keys, TTLs, and error responses for all endpoints
5. **Kubernetes YAML** - Full template manifests with envsubst variables and ConfigMap references
6. **Frontend Component Example** - Complete Dashboard.tsx with loading states, error handling, and Tailwind styling
7. **Seed Data Specifics** - Exact user names, team names, project descriptions, and task details
8. **TypeScript Configurations** - Complete tsconfig.json files for all packages
9. **Network Timeouts** - 30-second AbortController implementation for fetch calls
10. **Redis Cache Patterns** - Specific cache key formats and invalidation strategies

### Key Implementation Patterns Documented:
- **Error Handling**: `{ message: "..." }` format with 404/500 status codes
- **Pagination**: `?limit=10&offset=0` with direct array responses
- **Date Formatting**: `Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeStyle: 'short' })`
- **Health Checks**: `/health` (liveness) and `/health/ready` (readiness with DB/Redis checks)
- **Port Forwarding**: Background processes with PID tracking in `.pids/` directory
- **Volume Mounts**: hostPath with `${WORKSPACE_PATH}` substitution for hot reload
- **Graceful Degradation**: Redis failures logged but don't break API functionality

### Configuration Details Added:
- Complete `.env.example` with all 15 environment variables
- Exact resource limits for all services (CPU/memory requests and limits)
- Specific probe timings (initialDelaySeconds, periodSeconds, timeoutSeconds)
- CORS configuration (origin, credentials, methods)
- Database connection pooling (min: 2, max: 10)
- Complete package.json dependencies with version ranges

This enhanced task list provides developers with concrete, copy-pasteable code examples and eliminates ambiguity in implementation decisions.

---

**Document Version:** 2.0  
**Last Updated:** November 2025  
**Status:** Ready for Implementation - Enhanced with Complete Code Specifications


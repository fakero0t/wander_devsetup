# PR #4: API Service Implementation

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

**Goal:** Implement the complete Express.js API with all routes, database connectivity, Redis caching, and health checks.

## Files to Create

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

## Acceptance Criteria
- All endpoints return correct response formats (arrays for lists, objects for single, 204 for delete)
- Knex migrations run automatically on startup
- Redis caching works with graceful degradation
- Health endpoints return correct status
- CORS configured correctly
- Hot reload works with nodemon
- TypeScript compiles without errors


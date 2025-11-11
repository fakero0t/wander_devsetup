# PR #3: Database & Seed Script

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

**Goal:** Create PostgreSQL Docker image with initialization scripts and comprehensive seed data.

## Files to Create

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

## Acceptance Criteria
- Seed script runs without errors in PostgreSQL 14
- Idempotency works (running twice doesn't duplicate data)
- All foreign key constraints work correctly
- Exactly 5 users, 2 teams, 2 projects, 6 tasks, 10 activities
- All timestamps in UTC
- Indexes created successfully


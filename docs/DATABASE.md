# Wander - Database Documentation

Complete documentation of the Wander PostgreSQL database schema, relationships, and seed data.

## Overview

Wander uses **PostgreSQL 14** as its relational database. The schema supports a project management system with users, teams, projects, tasks, and an activity audit trail.

**Key Features:**
- Full ACID compliance
- Foreign key constraints with cascading deletes
- Indexed foreign keys for performance
- Idempotent seed script
- Timestamp tracking on all entities

## Database Configuration

**Connection Details (Development):**
- **Host:** postgres (Kubernetes service name) or localhost:5432 (port-forwarded)
- **Database:** `wander_dev`
- **User:** `postgres`
- **Password:** `dev_password` (development only!)
- **Port:** 5432

**Environment Variables:**
```bash
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=wander_dev
DATABASE_USER=postgres
DATABASE_PASSWORD=dev_password
DATABASE_POOL_SIZE=10
```

## Entity Relationship Diagram

```
┌─────────────────┐
│     users       │
│─────────────────│
│ id (PK)         │◄────────┐
│ name            │         │
│ email (UNIQUE)  │         │
│ created_at      │         │
│ updated_at      │         │
└─────────────────┘         │
        ▲                   │
        │                   │
        │ user_id           │ user_id
        │                   │
┌───────┴──────────┐   ┌────┴──────────┐
│  team_members    │   │  activities   │
│──────────────────│   │───────────────│
│ id (PK)          │   │ id (PK)       │
│ team_id (FK) ────┼──►│ user_id (FK)  │
│ user_id (FK)     │   │ action        │
│ joined_at        │   │ entity_type   │
└──────────────────┘   │ entity_id     │
        │              │ description   │
        │              │ created_at    │
        │              └───────────────┘
        │
        │ team_id
        │
┌───────▼──────────┐
│      teams       │
│──────────────────│
│ id (PK)          │
│ name (UNIQUE)    │
│ description      │
│ created_at       │
│ updated_at       │
└──────────────────┘
        ▲
        │
        │ team_id
        │
┌───────┴──────────┐
│    projects      │
│──────────────────│
│ id (PK)          │
│ team_id (FK)     │
│ name             │
│ description      │
│ status           │
│ created_at       │
│ updated_at       │
└──────────────────┘
        ▲
        │
        │ project_id
        │
┌───────┴──────────┐
│      tasks       │
│──────────────────│
│ id (PK)          │
│ project_id (FK)  │
│ assigned_to (FK) │─── references users(id)
│ title            │
│ description      │
│ status           │
│ priority         │
│ created_at       │
│ updated_at       │
└──────────────────┘
```

## Table Definitions

### users

Stores user accounts and profiles.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Auto-incrementing user ID |
| `name` | VARCHAR(255) | NOT NULL | Full name of the user |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | Email address (unique identifier) |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Account creation timestamp |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Constraints:**
- **Primary Key:** `id`
- **Unique:** `email`

**Indexes:**
- Primary key index on `id` (automatic)
- Unique index on `email` (automatic)

---

### teams

Stores team information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Auto-incrementing team ID |
| `name` | VARCHAR(255) | NOT NULL, UNIQUE | Team name |
| `description` | TEXT | NULL | Optional team description |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Team creation timestamp |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Constraints:**
- **Primary Key:** `id`
- **Unique:** `name`

**Indexes:**
- Primary key index on `id` (automatic)
- Unique index on `name` (automatic)

---

### team_members

Junction table for many-to-many relationship between users and teams.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Auto-incrementing membership ID |
| `team_id` | INTEGER | NOT NULL, FOREIGN KEY | References `teams(id)` |
| `user_id` | INTEGER | NOT NULL, FOREIGN KEY | References `users(id)` |
| `joined_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Timestamp when user joined team |

**Constraints:**
- **Primary Key:** `id`
- **Foreign Key:** `team_id` → `teams(id)` ON DELETE CASCADE
- **Foreign Key:** `user_id` → `users(id)` ON DELETE CASCADE

**Indexes:**
- Primary key index on `id` (automatic)
- Index on `team_id` (explicit)
- Index on `user_id` (explicit)

**Notes:**
- Cascade delete: Removing a team or user also removes memberships

---

### projects

Stores project information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Auto-incrementing project ID |
| `team_id` | INTEGER | NOT NULL, FOREIGN KEY | References `teams(id)` |
| `name` | VARCHAR(255) | NOT NULL | Project name |
| `description` | TEXT | NULL | Optional project description |
| `status` | VARCHAR(50) | NOT NULL, DEFAULT 'planning' | Project status enum |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Project creation timestamp |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Constraints:**
- **Primary Key:** `id`
- **Foreign Key:** `team_id` → `teams(id)` ON DELETE CASCADE
- **Check:** `status` IN ('planning', 'active', 'completed')

**Indexes:**
- Primary key index on `id` (automatic)
- Index on `team_id` (explicit)

**Status Values:**
- `planning`: Project is being planned
- `active`: Project is in progress
- `completed`: Project is finished

---

### tasks

Stores task information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Auto-incrementing task ID |
| `project_id` | INTEGER | NOT NULL, FOREIGN KEY | References `projects(id)` |
| `assigned_to` | INTEGER | NULL, FOREIGN KEY | References `users(id)` (optional) |
| `title` | VARCHAR(255) | NOT NULL | Task title |
| `description` | TEXT | NULL | Optional task description |
| `status` | VARCHAR(50) | NOT NULL, DEFAULT 'todo' | Task status enum |
| `priority` | VARCHAR(50) | NOT NULL, DEFAULT 'medium' | Task priority enum |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Task creation timestamp |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Constraints:**
- **Primary Key:** `id`
- **Foreign Key:** `project_id` → `projects(id)` ON DELETE CASCADE
- **Foreign Key:** `assigned_to` → `users(id)` ON DELETE SET NULL
- **Check:** `status` IN ('todo', 'in_progress', 'done')
- **Check:** `priority` IN ('low', 'medium', 'high')

**Indexes:**
- Primary key index on `id` (automatic)
- Index on `project_id` (explicit)
- Index on `assigned_to` (explicit)

**Status Values:**
- `todo`: Task not started
- `in_progress`: Task is being worked on
- `done`: Task is completed

**Priority Values:**
- `low`: Low priority
- `medium`: Medium priority
- `high`: High priority

**Notes:**
- `assigned_to` is nullable (tasks can be unassigned)
- Deleting a user sets `assigned_to` to NULL instead of deleting task

---

### activities

Audit trail / activity log for tracking user actions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Auto-incrementing activity ID |
| `user_id` | INTEGER | NOT NULL, FOREIGN KEY | References `users(id)` |
| `action` | VARCHAR(100) | NOT NULL | Action type (e.g., 'created', 'updated') |
| `entity_type` | VARCHAR(100) | NULL | Type of entity affected |
| `entity_id` | INTEGER | NULL | ID of affected entity |
| `description` | TEXT | NULL | Human-readable description |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Activity timestamp |

**Constraints:**
- **Primary Key:** `id`
- **Foreign Key:** `user_id` → `users(id)` ON DELETE CASCADE

**Indexes:**
- Primary key index on `id` (automatic)
- Index on `user_id` (explicit)

**Notes:**
- No foreign key on `entity_id` for flexibility across types
- `entity_type` indicates what kind of entity: 'task', 'project', etc.

## Foreign Key Relationships

### Cascade Rules

| Parent Table | Child Table | Column | On Delete |
|--------------|-------------|--------|-----------|
| `users` | `team_members` | `user_id` | CASCADE |
| `teams` | `team_members` | `team_id` | CASCADE |
| `teams` | `projects` | `team_id` | CASCADE |
| `projects` | `tasks` | `project_id` | CASCADE |
| `users` | `tasks` | `assigned_to` | SET NULL |
| `users` | `activities` | `user_id` | CASCADE |

**Cascade Behavior:**
- **CASCADE**: Deleting parent deletes all children
- **SET NULL**: Deleting parent sets child FK to NULL

**Example:**
- Deleting a team deletes all its projects, which deletes all those projects' tasks
- Deleting a user unassigns them from tasks (doesn't delete tasks)

## Indexes

All foreign keys are indexed for query performance:

```sql
CREATE INDEX idx_team_members_team_id ON team_members(team_id);
CREATE INDEX idx_team_members_user_id ON team_members(user_id);
CREATE INDEX idx_projects_team_id ON projects(team_id);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_activities_user_id ON activities(user_id);
```

**Performance Impact:**
- Speeds up JOIN operations
- Improves filtering by foreign key
- Slightly slows down INSERT/UPDATE (acceptable trade-off)

## Seed Data

The database is seeded with sample data for development and testing.

### users (5 records)

| ID | Name | Email |
|----|------|-------|
| 1 | Alice Anderson | alice@wander.com |
| 2 | Bob Baker | bob@wander.com |
| 3 | Carol Chen | carol@wander.com |
| 4 | David Davis | david@wander.com |
| 5 | Eve Evans | eve@wander.com |

### teams (2 records)

| ID | Name | Description |
|----|------|-------------|
| 1 | Engineering | Software engineering team |
| 2 | Product | Product management and design |

### team_members (5 records)

| Team | Members |
|------|---------|
| Engineering (1) | Alice (1), Bob (2), Carol (3) |
| Product (2) | David (4), Eve (5) |

### projects (2 records)

| ID | Team | Name | Status |
|----|------|------|--------|
| 1 | Engineering | Website Redesign | active |
| 2 | Product | Mobile App | planning |

### tasks (6 records)

| ID | Project | Title | Status | Priority | Assigned To |
|----|---------|-------|--------|----------|-------------|
| 1 | 1 | Design homepage mockup | done | high | Alice |
| 2 | 1 | Set up CI/CD pipeline | in_progress | medium | Bob |
| 3 | 1 | Implement user authentication | todo | high | Carol |
| 4 | 2 | Research competitor apps | done | medium | David |
| 5 | 2 | Create wireframes | in_progress | high | Eve |
| 6 | 2 | Define feature set | todo | low | David |

### activities (10 records)

Recent activities tracking user actions across the system. Includes task creation, updates, and completions with realistic timestamps.

## Idempotent Seed Script

The seed script (`db/init/seed.sql`) is designed to be idempotent:

```sql
DO $$
BEGIN
  -- Check if already seeded
  IF EXISTS (SELECT 1 FROM users LIMIT 1) THEN
    RAISE NOTICE 'Database already seeded. Skipping...';
    RETURN;
  END IF;

  -- Drop and recreate tables
  DROP TABLE IF EXISTS activities CASCADE;
  DROP TABLE IF EXISTS tasks CASCADE;
  -- ... etc

  -- Create tables and insert data
  -- ...
END $$;
```

**Benefits:**
- Can re-run without errors
- Easy to reset database to known state
- Simplifies development workflow

**Usage:**
```bash
make seed-db
```

## Common Queries

### Get all users in a team

```sql
SELECT u.id, u.name, u.email, tm.joined_at
FROM users u
JOIN team_members tm ON u.id = tm.user_id
WHERE tm.team_id = 1
ORDER BY tm.joined_at;
```

### Get all tasks for a project with assignee names

```sql
SELECT t.id, t.title, t.status, t.priority, u.name AS assigned_to_name
FROM tasks t
LEFT JOIN users u ON t.assigned_to = u.id
WHERE t.project_id = 1
ORDER BY t.created_at;
```

### Get recent activities with user names

```sql
SELECT a.*, u.name AS user_name
FROM activities a
JOIN users u ON a.user_id = u.id
ORDER BY a.created_at DESC
LIMIT 10;
```

### Count tasks by status for a project

```sql
SELECT status, COUNT(*) as count
FROM tasks
WHERE project_id = 1
GROUP BY status;
```

### Get projects with task counts

```sql
SELECT p.id, p.name, p.status, COUNT(t.id) AS task_count
FROM projects p
LEFT JOIN tasks t ON p.id = t.project_id
GROUP BY p.id, p.name, p.status
ORDER BY p.created_at;
```

## Database Migrations

Currently using a simple drop/recreate approach for development. For production:

**Recommended Tools:**
- **Flyway**: Java-based migration tool
- **Liquibase**: XML/YAML-based migrations
- **node-pg-migrate**: Node.js migration tool
- **Knex.js**: JavaScript query builder with migrations

**Migration Strategy:**
1. Version each schema change
2. Never modify existing migrations
3. Test migrations on copy of production data
4. Always have rollback strategy

## Backup and Restore

### Backup

```bash
# From host machine (with port-forward active)
pg_dump -h localhost -p 5432 -U postgres -d wander_dev > backup.sql

# From Kubernetes pod
kubectl exec -n wander-dev postgres-xxxxx -- \
  pg_dump -U postgres wander_dev > backup.sql
```

### Restore

```bash
# From host machine
psql -h localhost -p 5432 -U postgres -d wander_dev < backup.sql

# From Kubernetes pod
kubectl exec -i -n wander-dev postgres-xxxxx -- \
  psql -U postgres wander_dev < backup.sql
```

## Database Access

### Using make db-shell

```bash
make db-shell
```

This opens a `psql` session in the PostgreSQL pod.

### Common psql Commands

```sql
\dt              -- List all tables
\d users         -- Describe users table
\d+ tasks        -- Describe tasks with more details
\di              -- List all indexes
\df              -- List all functions
\l               -- List all databases
\du              -- List all users/roles
\c wander_dev    -- Connect to wander_dev database
\q               -- Quit psql
```

### Query Examples

```sql
-- Count all records in each table
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM teams;
SELECT COUNT(*) FROM team_members;
SELECT COUNT(*) FROM projects;
SELECT COUNT(*) FROM tasks;
SELECT COUNT(*) FROM activities;

-- View recent activities
SELECT * FROM activities ORDER BY created_at DESC LIMIT 10;

-- Find tasks assigned to Alice
SELECT t.* FROM tasks t
JOIN users u ON t.assigned_to = u.id
WHERE u.name = 'Alice Anderson';
```

## Performance Considerations

### Connection Pooling

API uses connection pooling (pg Pool) with `DATABASE_POOL_SIZE=10`.

**Benefits:**
- Reuses connections
- Reduces connection overhead
- Limits concurrent connections

### Query Optimization

**Indexed Queries (Fast):**
- Lookups by primary key
- Joins on foreign keys
- Filtering by indexed columns

**Slow Queries (Avoid in Production):**
- Full table scans
- LIKE with leading wildcard (`%search`)
- Unindexed WHERE clauses

### Monitoring

Production should monitor:
- Connection pool usage
- Slow query log
- Index usage statistics
- Table bloat
- Replication lag (if using replicas)

## Future Enhancements

Potential database improvements:

1. **Full-text Search**: Add `tsvector` columns for search
2. **Soft Deletes**: Add `deleted_at` column instead of hard deletes
3. **Audit Triggers**: Automatic activity logging via triggers
4. **Partitioning**: Partition activities table by date
5. **Read Replicas**: For scaling read-heavy workloads
6. **JSON Columns**: Store flexible metadata
7. **Row-Level Security**: PostgreSQL RLS for multi-tenancy
8. **Materialized Views**: Pre-compute complex aggregations

## Related Documentation

- [API Reference](./API.md) - How to query this data via API
- [Architecture](./ARCHITECTURE.md) - How database fits into system
- [Setup Guide](./SETUP.md) - How to initialize database
- [Troubleshooting](./TROUBLESHOOTING.md) - Database connection issues


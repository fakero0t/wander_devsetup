# Wander - API Reference

Complete reference for all Wander API endpoints.

## Base URL

```
http://localhost:4000
```

## Response Format

All API responses use JSON format. Successful responses return the requested data. Error responses include an error message.

### Success Response

```json
{
  "id": 1,
  "name": "Example"
}
```

### Error Response

```json
{
  "error": "Error message description"
}
```

## Common Query Parameters

### Pagination

Most list endpoints support pagination:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `limit` | integer | 50 | Maximum number of results to return |
| `offset` | integer | 0 | Number of results to skip |

Example:
```bash
curl "http://localhost:4000/api/users?limit=10&offset=20"
```

## Health Endpoints

### GET /health

Basic health check endpoint.

**Response:**
```json
{
  "status": "ok"
}
```

**Example:**
```bash
curl http://localhost:4000/health
```

---

### GET /health/ready

Readiness check that verifies database and Redis connectivity.

**Response:**
```json
{
  "status": "ok",
  "services": {
    "db": "connected",
    "redis": "connected"
  }
}
```

**Error Response (503):**
```json
{
  "status": "error",
  "services": {
    "db": "disconnected",
    "redis": "connected"
  }
}
```

**Example:**
```bash
curl http://localhost:4000/health/ready
```

---

## Users Endpoints

### GET /api/users

Get all users.

**Query Parameters:**
- `limit` (optional): Maximum results (default: 50)
- `offset` (optional): Skip N results (default: 0)

**Response:**
```json
[
  {
    "id": 1,
    "name": "Alice Anderson",
    "email": "alice@wander.com",
    "created_at": "2024-01-15T08:00:00.000Z",
    "updated_at": "2024-01-15T08:00:00.000Z"
  },
  {
    "id": 2,
    "name": "Bob Baker",
    "email": "bob@wander.com",
    "created_at": "2024-01-16T09:30:00.000Z",
    "updated_at": "2024-01-16T09:30:00.000Z"
  }
]
```

**Example:**
```bash
# Get all users
curl http://localhost:4000/api/users

# Get first 2 users
curl http://localhost:4000/api/users?limit=2

# Get users with offset
curl http://localhost:4000/api/users?limit=5&offset=2
```

---

### GET /api/users/:id

Get a specific user by ID.

**Parameters:**
- `id` (path): User ID

**Response:**
```json
{
  "id": 1,
  "name": "Alice Anderson",
  "email": "alice@wander.com",
  "created_at": "2024-01-15T08:00:00.000Z",
  "updated_at": "2024-01-15T08:00:00.000Z"
}
```

**Error Response (404):**
```json
{
  "error": "User not found"
}
```

**Example:**
```bash
curl http://localhost:4000/api/users/1
```

---

## Teams Endpoints

### GET /api/teams

Get all teams.

**Query Parameters:**
- `limit` (optional): Maximum results (default: 50)
- `offset` (optional): Skip N results (default: 0)

**Response:**
```json
[
  {
    "id": 1,
    "name": "Engineering",
    "description": "Software engineering team",
    "created_at": "2024-01-10T10:00:00.000Z",
    "updated_at": "2024-01-10T10:00:00.000Z"
  },
  {
    "id": 2,
    "name": "Product",
    "description": "Product management and design",
    "created_at": "2024-01-10T11:00:00.000Z",
    "updated_at": "2024-01-10T11:00:00.000Z"
  }
]
```

**Example:**
```bash
curl http://localhost:4000/api/teams
```

---

### GET /api/teams/:id

Get a specific team by ID.

**Parameters:**
- `id` (path): Team ID

**Response:**
```json
{
  "id": 1,
  "name": "Engineering",
  "description": "Software engineering team",
  "created_at": "2024-01-10T10:00:00.000Z",
  "updated_at": "2024-01-10T10:00:00.000Z"
}
```

**Error Response (404):**
```json
{
  "error": "Team not found"
}
```

**Example:**
```bash
curl http://localhost:4000/api/teams/1
```

---

### GET /api/teams/:id/members

Get all members of a specific team.

**Parameters:**
- `id` (path): Team ID

**Response:**
```json
[
  {
    "id": 1,
    "team_id": 1,
    "user_id": 1,
    "joined_at": "2024-01-15T08:00:00.000Z",
    "user": {
      "id": 1,
      "name": "Alice Anderson",
      "email": "alice@wander.com"
    }
  },
  {
    "id": 2,
    "team_id": 1,
    "user_id": 2,
    "joined_at": "2024-01-16T09:30:00.000Z",
    "user": {
      "id": 2,
      "name": "Bob Baker",
      "email": "bob@wander.com"
    }
  }
]
```

**Example:**
```bash
curl http://localhost:4000/api/teams/1/members
```

---

## Projects Endpoints

### GET /api/projects

Get all projects.

**Query Parameters:**
- `limit` (optional): Maximum results (default: 50)
- `offset` (optional): Skip N results (default: 0)
- `team_id` (optional): Filter by team ID
- `status` (optional): Filter by status (`planning`, `active`, `completed`)

**Response:**
```json
[
  {
    "id": 1,
    "team_id": 1,
    "name": "Website Redesign",
    "description": "Complete overhaul of company website",
    "status": "active",
    "created_at": "2024-02-01T10:00:00.000Z",
    "updated_at": "2024-02-01T10:00:00.000Z"
  },
  {
    "id": 2,
    "team_id": 2,
    "name": "Mobile App",
    "description": "New mobile application",
    "status": "planning",
    "created_at": "2024-02-05T14:00:00.000Z",
    "updated_at": "2024-02-05T14:00:00.000Z"
  }
]
```

**Example:**
```bash
# Get all projects
curl http://localhost:4000/api/projects

# Filter by team
curl http://localhost:4000/api/projects?team_id=1

# Filter by status
curl http://localhost:4000/api/projects?status=active
```

---

### GET /api/projects/:id

Get a specific project by ID.

**Parameters:**
- `id` (path): Project ID

**Response:**
```json
{
  "id": 1,
  "team_id": 1,
  "name": "Website Redesign",
  "description": "Complete overhaul of company website",
  "status": "active",
  "created_at": "2024-02-01T10:00:00.000Z",
  "updated_at": "2024-02-01T10:00:00.000Z"
}
```

**Error Response (404):**
```json
{
  "error": "Project not found"
}
```

**Example:**
```bash
curl http://localhost:4000/api/projects/1
```

---

### GET /api/projects/:id/tasks

Get all tasks for a specific project.

**Parameters:**
- `id` (path): Project ID

**Query Parameters:**
- `status` (optional): Filter by status (`todo`, `in_progress`, `done`)
- `priority` (optional): Filter by priority (`low`, `medium`, `high`)

**Response:**
```json
[
  {
    "id": 1,
    "project_id": 1,
    "assigned_to": 1,
    "title": "Design homepage mockup",
    "description": "Create initial design concepts",
    "status": "done",
    "priority": "high",
    "created_at": "2024-02-02T09:00:00.000Z",
    "updated_at": "2024-02-03T16:00:00.000Z"
  }
]
```

**Example:**
```bash
# Get all tasks for project
curl http://localhost:4000/api/projects/1/tasks

# Filter by status
curl http://localhost:4000/api/projects/1/tasks?status=in_progress
```

---

## Tasks Endpoints

### GET /api/tasks

Get all tasks.

**Query Parameters:**
- `limit` (optional): Maximum results (default: 50)
- `offset` (optional): Skip N results (default: 0)
- `project_id` (optional): Filter by project ID
- `assigned_to` (optional): Filter by user ID
- `status` (optional): Filter by status (`todo`, `in_progress`, `done`)
- `priority` (optional): Filter by priority (`low`, `medium`, `high`)

**Response:**
```json
[
  {
    "id": 1,
    "project_id": 1,
    "assigned_to": 1,
    "title": "Design homepage mockup",
    "description": "Create initial design concepts",
    "status": "done",
    "priority": "high",
    "created_at": "2024-02-02T09:00:00.000Z",
    "updated_at": "2024-02-03T16:00:00.000Z"
  }
]
```

**Example:**
```bash
# Get all tasks
curl http://localhost:4000/api/tasks

# Filter by status and priority
curl "http://localhost:4000/api/tasks?status=in_progress&priority=high"

# Get tasks assigned to user 1
curl http://localhost:4000/api/tasks?assigned_to=1
```

---

### GET /api/tasks/:id

Get a specific task by ID.

**Parameters:**
- `id` (path): Task ID

**Response:**
```json
{
  "id": 1,
  "project_id": 1,
  "assigned_to": 1,
  "title": "Design homepage mockup",
  "description": "Create initial design concepts",
  "status": "done",
  "priority": "high",
  "created_at": "2024-02-02T09:00:00.000Z",
  "updated_at": "2024-02-03T16:00:00.000Z"
}
```

**Error Response (404):**
```json
{
  "error": "Task not found"
}
```

**Example:**
```bash
curl http://localhost:4000/api/tasks/1
```

---

## Activities Endpoints

### GET /api/activities

Get recent activities (activity log/audit trail).

**Query Parameters:**
- `limit` (optional): Maximum results (default: 50)
- `offset` (optional): Skip N results (default: 0)
- `user_id` (optional): Filter by user ID
- `entity_type` (optional): Filter by entity type (e.g., `task`, `project`)

**Response:**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "action": "created",
    "entity_type": "task",
    "entity_id": 1,
    "description": "Alice Anderson created task 'Design homepage mockup'",
    "created_at": "2024-02-02T09:00:00.000Z"
  },
  {
    "id": 2,
    "user_id": 2,
    "action": "updated",
    "entity_type": "task",
    "entity_id": 2,
    "description": "Bob Baker updated task 'Set up CI/CD pipeline'",
    "created_at": "2024-02-02T10:15:00.000Z"
  }
]
```

**Example:**
```bash
# Get recent activities
curl http://localhost:4000/api/activities

# Get activities for specific user
curl http://localhost:4000/api/activities?user_id=1

# Get task-related activities
curl http://localhost:4000/api/activities?entity_type=task

# Get first 10 activities
curl http://localhost:4000/api/activities?limit=10
```

---

## Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET request |
| 201 | Created | Successful POST (resource created) |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid request parameters |
| 404 | Not Found | Resource not found |
| 500 | Internal Server Error | Server-side error |
| 503 | Service Unavailable | Service dependencies unavailable |

## Error Handling

All errors return JSON with an `error` field:

```json
{
  "error": "Description of what went wrong"
}
```

### Common Errors

**404 Not Found:**
```bash
curl http://localhost:4000/api/users/999
```
```json
{
  "error": "User not found"
}
```

**400 Bad Request:**
```bash
curl "http://localhost:4000/api/tasks?status=invalid"
```
```json
{
  "error": "Invalid status value. Must be: todo, in_progress, done"
}
```

**503 Service Unavailable:**
```bash
curl http://localhost:4000/health/ready
# (when database is down)
```
```json
{
  "status": "error",
  "services": {
    "db": "disconnected",
    "redis": "connected"
  }
}
```

## Data Types Reference

### User

```typescript
{
  id: number;
  name: string;
  email: string;
  created_at: string; // ISO 8601 timestamp
  updated_at: string; // ISO 8601 timestamp
}
```

### Team

```typescript
{
  id: number;
  name: string;
  description: string | null;
  created_at: string;
  updated_at: string;
}
```

### TeamMember

```typescript
{
  id: number;
  team_id: number;
  user_id: number;
  joined_at: string;
}
```

### Project

```typescript
{
  id: number;
  team_id: number;
  name: string;
  description: string | null;
  status: 'planning' | 'active' | 'completed';
  created_at: string;
  updated_at: string;
}
```

### Task

```typescript
{
  id: number;
  project_id: number;
  assigned_to: number | null;
  title: string;
  description: string | null;
  status: 'todo' | 'in_progress' | 'done';
  priority: 'low' | 'medium' | 'high';
  created_at: string;
  updated_at: string;
}
```

### Activity

```typescript
{
  id: number;
  user_id: number;
  action: string;
  entity_type: string | null;
  entity_id: number | null;
  description: string | null;
  created_at: string;
}
```

## Pagination Examples

### Basic Pagination

Get first page (10 items):
```bash
curl "http://localhost:4000/api/users?limit=10&offset=0"
```

Get second page (next 10 items):
```bash
curl "http://localhost:4000/api/users?limit=10&offset=10"
```

Get third page:
```bash
curl "http://localhost:4000/api/users?limit=10&offset=20"
```

### Check if More Results Exist

If the response has fewer items than `limit`, you've reached the end:

```bash
# Request 10 items, get 5 back → no more results
curl "http://localhost:4000/api/users?limit=10&offset=0"
# Returns 5 users → this is the last page
```

## Testing the API

### Using curl

All examples in this document use `curl`. Make sure the API is running:

```bash
make dev
```

Then test any endpoint:

```bash
curl http://localhost:4000/health
```

### Using a REST Client

You can also use tools like:
- **Postman**: Import these examples
- **Insomnia**: REST client with nice UI
- **HTTPie**: Command-line alternative to curl
  ```bash
  http GET localhost:4000/api/users
  ```

### From the Frontend

The frontend uses the API automatically. Just open http://localhost:3000 and navigate through the UI.

## Rate Limiting

Currently no rate limiting is implemented. In production, consider:
- Rate limiting by IP or API key
- Different limits for authenticated vs. anonymous
- Redis-based rate limiting for distributed systems

## Authentication

Currently no authentication is required. In production, implement:
- JWT tokens for authentication
- OAuth 2.0 for third-party integration
- API keys for service-to-service
- RBAC for authorization

## CORS

CORS is configured to allow requests from the frontend (http://localhost:3000) in development.

Production should restrict CORS to specific origins.

## WebSocket Support

Not currently implemented. Future consideration for real-time updates:
- Task status changes
- New activities
- Team member presence
- Live notifications

## API Versioning

Currently no versioning. Future API versions would use path prefix:
- `/v1/api/users`
- `/v2/api/users`

## Related Documentation

- [Setup Guide](./SETUP.md) - Get the API running
- [Architecture](./ARCHITECTURE.md) - System design
- [Database Schema](./DATABASE.md) - Data model details
- [Troubleshooting](./TROUBLESHOOTING.md) - Common issues


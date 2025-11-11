# Contributing to Wander

Thank you for your interest in contributing to Wander! This document provides guidelines and workflows for contributing to the project.

## Development Workflow

### 1. Setting Up Your Environment

Before you start contributing, ensure your development environment is properly set up:

```bash
# Clone the repository
git clone <repository-url>
cd wander_devsetup

# Install dependencies
npm install

# Start Minikube
minikube start --memory=4096 --cpus=2

# Configure Docker environment
eval $(minikube docker-env)

# Build images
make build

# Start development environment
make dev
```

Verify everything works:
```bash
make test
```

### 2. Making Changes

**Step 1: Create a branch (optional for single-developer workflow)**
```bash
git checkout -b feature/your-feature-name
```

**Step 2: Make your changes**
- Edit files in your IDE (VS Code recommended)
- Follow code style guidelines (see below)
- Write tests for new features

**Step 3: Test your changes locally**
```bash
# Rebuild relevant services
make build

# Restart environment
make restart

# Run tests
make test

# Manual testing
curl http://localhost:4000/api/your-new-endpoint
```

**Step 4: Lint your code**
```bash
npm run lint

# Fix auto-fixable issues
npm run lint -- --fix
```

### 3. Committing Changes

**Commit Message Guidelines:**

We use freeform commit messages. Keep them clear and descriptive:

**Good commit messages:**
```
Add user authentication endpoint
Fix database connection pool leak
Update README with troubleshooting steps
Refactor task service for better performance
```

**Less helpful messages:**
```
Update
Fix stuff
WIP
Changes
```

**Making commits:**
```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "Add pagination support to users API"

# Push to repository
git push origin main
```

### 4. Branch Strategy

Wander uses a **single main branch** strategy for simplicity:

```
main (always deployable)
  ↓
  Commits directly to main
```

**When to branch (optional):**
- Experimental features
- Major refactoring
- Multiple developers working simultaneously

**When to commit to main (preferred):**
- Small, tested changes
- Bug fixes
- Documentation updates
- Single developer workflow

### 5. Code Review (if applicable)

If working in a team:
- Create a Pull Request on GitHub
- Request review from team members
- Address feedback
- Merge when approved

If working solo:
- Ensure all tests pass
- Review your own changes
- Commit directly to main

## Code Style Guidelines

### TypeScript / JavaScript

**General Rules:**
- Use TypeScript for type safety
- Use `const` for immutable values, `let` for mutable
- Avoid `var`
- Prefer arrow functions for callbacks
- Use async/await over raw promises

**ESLint Configuration:**

The project uses ESLint with these rules:
- `@typescript-eslint/no-explicit-any: off` - `any` is allowed
- `no-console: off` - Console logs are allowed
- `@typescript-eslint/no-unused-vars: warn` - Unused vars warn (not error)

**Formatting:**
- 2 spaces for indentation
- Single quotes for strings
- Semicolons required
- Trailing commas in multi-line objects/arrays

**Example:**
```typescript
// Good
const fetchUsers = async (): Promise<User[]> => {
  const result = await pool.query('SELECT * FROM users');
  return result.rows;
};

// Avoid
var getUsers = function() {
  return pool.query('SELECT * FROM users').then(function(result) {
    return result.rows
  })
}
```

### React Components

**Component Structure:**
```typescript
import { useState, useEffect } from 'react';
import { apiGet } from '@/api/client';
import { User } from '@wander/shared';

export function UserList() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiGet<User[]>('/api/users')
      .then(setUsers)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      {users.map(user => (
        <div key={user.id}>{user.name}</div>
      ))}
    </div>
  );
}
```

**Best Practices:**
- Use functional components (not class components)
- Use hooks for state and side effects
- Extract reusable logic into custom hooks
- Keep components small and focused
- Use TypeScript interfaces for props

### CSS / Tailwind

**Preferred: Tailwind utility classes**
```tsx
<div className="container mx-auto p-4">
  <h1 className="text-2xl font-bold mb-4">Title</h1>
</div>
```

**Custom CSS (when needed):**
- Place in component-specific files
- Use BEM naming convention
- Avoid global styles

### API Endpoints

**Naming:**
- Use kebab-case for URLs: `/api/team-members`
- Use plural nouns: `/api/users` not `/api/user`
- Use nested resources: `/api/projects/:id/tasks`

**Structure:**
```typescript
// Good
router.get('/api/users', async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const result = await pool.query(
      'SELECT * FROM users LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

**Error Handling:**
- Always use try-catch for async operations
- Return appropriate HTTP status codes
- Include error messages in response
- Log errors to console

### Database Queries

**Use parameterized queries (prevent SQL injection):**
```typescript
// Good
const result = await pool.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);

// NEVER do this (SQL injection risk)
const result = await pool.query(
  `SELECT * FROM users WHERE id = ${userId}`
);
```

**Naming:**
- Use `snake_case` for table and column names
- Use descriptive names
- Prefix indexes with `idx_`

## Testing Guidelines

### Integration Tests

**Location:** `tests/integration.test.ts`

**Writing Tests:**
```typescript
import { describe, test, expect } from '@jest/globals';

describe('Feature Name', () => {
  test('should do something specific', async () => {
    const response = await fetch('http://localhost:4000/api/endpoint');
    expect(response.status).toBe(200);
    const data = await response.json();
    expect(data).toHaveProperty('id');
  });
});
```

**Best Practices:**
- Test behavior, not implementation
- Use descriptive test names
- Test happy path and error cases
- Use seed data for predictable results
- Clean up after tests (if creating data)

**Running Tests:**
```bash
# Run all tests
make test

# Run specific test file
npm test tests/integration.test.ts

# Run tests with pattern
npm test -- --testNamePattern="User"

# Run with coverage
npm test -- --coverage
```

### Unit Tests (Future)

When adding unit tests:
- Place near source: `src/services/__tests__/user.test.ts`
- Mock external dependencies
- Focus on pure functions
- Aim for high coverage on business logic

## Pull Request Checklist

Before submitting a PR (or committing to main):

- [ ] Code follows style guidelines
- [ ] All tests pass (`make test`)
- [ ] Linting passes (`npm run lint`)
- [ ] No console errors or warnings
- [ ] Documentation updated (if needed)
- [ ] API endpoints documented in `docs/API.md` (if added)
- [ ] Database schema updated (if changed)
- [ ] Docker images rebuild successfully
- [ ] Tested in local Kubernetes environment

## Project Structure

Understanding the codebase structure:

```
wander_devsetup/
├── packages/
│   └── shared/              # Shared TypeScript types
│       ├── src/
│       │   ├── types/       # Interface definitions
│       │   ├── constants/   # Enum values
│       │   └── index.ts     # Central export
│       └── package.json
│
├── services/
│   ├── api/                 # Backend API (to be implemented)
│   │   ├── src/
│   │   │   ├── routes/      # Express routes
│   │   │   ├── services/    # Business logic
│   │   │   └── index.ts     # Entry point
│   │   ├── Dockerfile
│   │   └── package.json
│   │
│   └── frontend/            # React frontend
│       ├── src/
│       │   ├── components/  # React components
│       │   ├── pages/       # Page components
│       │   ├── api/         # API client
│       │   ├── styles/      # CSS files
│       │   ├── App.tsx      # App router
│       │   └── main.tsx     # Entry point
│       ├── Dockerfile
│       └── package.json
│
├── db/
│   ├── init/
│   │   └── seed.sql         # Database initialization
│   └── Dockerfile
│
├── infra/
│   ├── k8s/                 # Kubernetes manifests (templates)
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── postgres.yaml
│   │   ├── redis.yaml
│   │   ├── api.yaml
│   │   └── frontend.yaml
│   └── generated/           # Generated manifests (gitignored)
│
├── scripts/                 # Automation scripts
│   ├── preflight-check.sh
│   ├── wait-for-services.sh
│   ├── prepare-manifests.sh
│   ├── handle-error.sh
│   └── validate-seed.sh
│
├── tests/
│   ├── integration.test.ts  # Integration tests
│   └── fixtures/            # Test data
│
├── docs/                    # Documentation
│   ├── SETUP.md
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── DATABASE.md
│   ├── KUBERNETES.md
│   ├── TROUBLESHOOTING.md
│   └── CONTRIBUTING.md
│
├── Makefile                 # Automation commands
├── package.json             # Root workspace config
├── tsconfig.base.json       # TypeScript config
├── .eslintrc.json           # ESLint config
├── jest.config.js           # Jest config
└── README.md                # Project overview
```

## Common Development Tasks

### Adding a New API Endpoint

1. Define types in `packages/shared/src/types/` (if needed)
2. Create route handler in `services/api/src/routes/`
3. Add route to main router
4. Document in `docs/API.md`
5. Write integration test in `tests/integration.test.ts`
6. Rebuild and test:
   ```bash
   make build
   make restart
   make test
   ```

### Adding a New Frontend Page

1. Create page component in `services/frontend/src/pages/`
2. Add route in `services/frontend/src/App.tsx`
3. Add navigation link in `Nav.tsx` component
4. Use shared types from `@wander/shared`
5. Rebuild and test:
   ```bash
   make build
   make restart
   ```

### Modifying Database Schema

1. Edit `db/init/seed.sql`
2. Update corresponding types in `packages/shared/src/types/`
3. Update documentation in `docs/DATABASE.md`
4. Delete and recreate PostgreSQL pod:
   ```bash
   kubectl delete pod -n wander-dev postgres-xxxxx
   ```
5. Test:
   ```bash
   make db-shell
   \dt
   \d table_name
   ```

### Adding a New Package Dependency

**Root dependencies:**
```bash
npm install --save-dev package-name
```

**Workspace dependencies:**
```bash
npm install package-name --workspace=packages/shared
npm install package-name --workspace=services/api
npm install package-name --workspace=services/frontend
```

**After adding dependencies:**
```bash
make build
make restart
```

### Debugging

**API Debugging:**
```bash
# View logs
make logs-api

# Exec into pod
make shell-api

# Attach debugger (if debug port exposed)
# VS Code: Use launch configuration
```

**Frontend Debugging:**
```bash
# View logs
make logs-frontend

# Open browser dev tools
# http://localhost:3000
# F12 → Console / Network tabs
```

**Database Debugging:**
```bash
# Open psql shell
make db-shell

# Check data
SELECT * FROM users;
\d users
```

## Getting Help

If you're stuck or have questions:

1. **Check documentation:**
   - [Setup Guide](./SETUP.md)
   - [Troubleshooting Guide](./TROUBLESHOOTING.md)
   - [Architecture Docs](./ARCHITECTURE.md)

2. **Search for similar issues:**
   - GitHub Issues (if available)
   - Stack Overflow
   - Project discussions

3. **Ask for help:**
   - Open a GitHub issue
   - Reach out to maintainers
   - Join community chat (if available)

## Code of Conduct

**Be respectful:**
- Welcome newcomers
- Be patient with questions
- Provide constructive feedback
- Respect different opinions

**Be collaborative:**
- Share knowledge
- Help others learn
- Document your decisions
- Credit contributors

## License

By contributing to Wander, you agree that your contributions will be licensed under the project's license.

## Recognition

Contributors will be recognized in the project README (if applicable).

Thank you for contributing to Wander! 🎉


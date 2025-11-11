# PR #8: Integration Tests

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

**Goal:** Create Jest integration tests that verify the entire system works end-to-end.

## Files to Create

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

## Acceptance Criteria
- All tests pass against running environment
- Tests cover all major endpoints
- Health checks verify DB and Redis connectivity
- Pagination tests verify correct behavior
- Tests run in serial with `--runInBand`
- Coverage report generated


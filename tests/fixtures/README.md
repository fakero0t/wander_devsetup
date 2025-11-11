# Test Fixtures

This directory is reserved for test fixtures, but the integration tests currently use live seed data from the database instead.

## Why No Fixtures?

The Wander integration tests are designed to run against a live development environment with seeded data. This approach:

1. **Tests the Real System**: Validates the complete stack including database connections, migrations, and seed scripts
2. **Simplifies Maintenance**: No need to keep fixtures in sync with schema changes
3. **Verifies Data Integrity**: Ensures the seed script creates data correctly

## Seed Data

The database is seeded with:
- 5 users
- 2 teams
- 2 projects
- 6 tasks
- 10 activities

Tests expect this data to be present. If tests fail, verify the database has been seeded:

```bash
make seed-db
```

## Future Considerations

If isolated unit testing is needed, fixtures can be added here. For now, integration tests provide end-to-end validation of the entire system.


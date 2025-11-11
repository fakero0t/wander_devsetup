# PR #1: Project Setup & Monorepo Structure

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

**Goal:** Establish the foundational repository structure with npm workspaces, base configurations, and development tooling.

## Files to Create

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

## Acceptance Criteria
- `npm install` runs successfully
- All workspaces are recognized
- ESLint runs without errors
- Directory structure matches PRD specification
- `.nvmrc` specifies Node 20


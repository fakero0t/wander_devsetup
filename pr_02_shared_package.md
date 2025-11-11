# PR #2: Shared Package Implementation

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

**Goal:** Create the shared package with all TypeScript types, constants, and utility functions used by both API and Frontend.

## Files to Create

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

## Acceptance Criteria
- `npm run build` in shared package compiles successfully
- `dist/` folder contains compiled JavaScript and type declarations
- All types match database schema from PRD
- Enums match canonical values from PRD (todo/in_progress/done, low/medium/high)


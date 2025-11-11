# PR #5: Frontend Application Implementation

**Project ID:** 3MCcAvCyK7F77BpbXUSI_1762376408364  
**Organization:** Wander  
**Date:** November 2025

**Goal:** Build the complete React frontend with all pages, components, routing, and API integration.

## Files to Create

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

## Acceptance Criteria
- All pages render without errors
- Routing works with clean URLs (BrowserRouter)
- API integration functions correctly
- Forms submit data successfully
- Modal dialogs open and close properly
- Empty states display correctly
- Loading states show during fetch
- Tailwind styles applied correctly
- Hot module replacement works


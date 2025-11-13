# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /workspace

# Copy workspace configuration
COPY package*.json tsconfig.base.json ./
COPY packages/shared ./packages/shared
COPY services/frontend ./services/frontend

# Install dependencies
RUN npm install --workspaces --no-audit --no-fund

# Build shared package first
RUN npm run build --workspace=@wander/shared

# Build frontend
RUN npm run build --workspace=@wander/frontend

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


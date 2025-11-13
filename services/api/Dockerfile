# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /workspace
# Copy workspace configuration
COPY package*.json tsconfig.base.json ./
COPY packages/shared ./packages/shared
COPY services/api ./services/api
# Install all dependencies including dev dependencies (no lockfile requirement)
RUN npm install --workspaces --no-audit --no-fund
# Build shared package first
RUN npm run build --workspace=packages/shared
# Build API
RUN npm run build --workspace=services/api

# Stage 2: Runtime
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app/services/api
# Install production deps for API only (no workspaces)
RUN apk add --no-cache --virtual .gyp python3 make g++
COPY services/api/package.json ./
RUN npm install --omit=dev --no-audit --no-fund && apk del .gyp
# Copy built artifacts
COPY --from=builder /workspace/services/api/dist ./dist
# Expose ports
EXPOSE 4000 9229
# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s \
  CMD node -e "require('http').get('http://localhost:4000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"
# Start command
CMD ["node", "dist/index.js"]


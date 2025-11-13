# Pull Request: Config File Customization Feature

## Overview

Add cross-platform configuration file support using YAML, replacing the current `.env.example` approach. This provides a single source of truth for environment configuration with environment-specific overrides, validation, and seamless integration with existing services.

## Goals

- Single source of truth: `config.yaml` replaces `.env.example`
- Cross-platform: Node.js-based loader works on Windows, macOS, Linux
- Environment-specific overrides via `NODE_ENV`
- Validation with clear error messages
- Backward compatible with existing service code (no changes needed)
- Generates `.env` files for services that expect them

## Files to Create

### 1. `config.yaml`
Main configuration file (committed to repo).

**Structure:**
```yaml
defaults:
  database:
    host: postgres
    port: 5432
    name: wander_dev
    user: postgres
    password: dev_password
    poolSize: 10
  
  api:
    host: 0.0.0.0
    port: 4000
    debugPort: 9229
    logLevel: debug
  
  frontend:
    host: 0.0.0.0
    port: 3000
    apiUrl: http://localhost:4000
  
  redis:
    host: redis
    port: 6379
  
  environment: development
  nodeEnv: development

environments:
  development:
    # Uses defaults, no overrides needed
  
  production:
    database:
      name: wander_prod
      password: ${DATABASE_PASSWORD}  # Must be set in environment
    api:
      logLevel: info
    environment: production
    nodeEnv: production
```

### 2. `config.yaml.example`
Template file with comments explaining each field (committed to repo).

### 3. `scripts/load-config.js`
Node.js script that:
- Loads and parses `config.yaml` using `js-yaml`
- Merges with `config.local.yaml` if present (local overrides)
- Selects environment based on `NODE_ENV` (defaults to `development`)
- Resolves `${VAR}` placeholders from `process.env`
- Validates required fields and types
- Flattens nested structure to environment variables
- Generates multiple output formats:
  - `.env` file (for services)
  - `.config.env` file (shell exports for Makefile)
  - ConfigMap data (for Kubernetes)
  - JSON output (for debugging)

**Command-line interface:**
```bash
node scripts/load-config.js                    # Generate .env and .config.env
node scripts/load-config.js --format env      # Generate .env only
node scripts/load-config.js --format shell-export  # Generate .config.env only
node scripts/load-config.js --format configmap    # Output ConfigMap data
node scripts/load-config.js --format json         # Output JSON
node scripts/load-config.js --validate-only       # Validate without generating
```

**Error handling:**
- Missing `config.yaml` → fail with: `Error: config.yaml not found. Please create it from config.yaml.example`
- Invalid YAML → fail with parse error details
- Missing required fields → fail with list of missing fields
- Invalid types → fail with type mismatch details
- Missing env var for `${VAR}` → fail with which variable is missing

**Required fields:**
- `database.host`, `database.port`, `database.name`, `database.user`, `database.password`
- `api.host`, `api.port`
- `frontend.host`, `frontend.port`, `frontend.apiUrl`
- `redis.host`, `redis.port`
- `environment`, `nodeEnv`

**Type validation:**
- Ports: integers, range 1-65535
- Hosts: non-empty strings
- URLs: valid URL format (for `frontend.apiUrl`)
- Log levels: enum (`debug`, `info`, `warn`, `error`)
- Pool size: positive integer

**Environment variable mapping:**
- `database.host` → `DATABASE_HOST`
- `database.port` → `DATABASE_PORT`
- `database.name` → `DATABASE_NAME`
- `database.user` → `DATABASE_USER`
- `database.password` → `DATABASE_PASSWORD`
- `database.poolSize` → `DATABASE_POOL_SIZE`
- `api.host` → `API_HOST`
- `api.port` → `API_PORT`
- `api.debugPort` → `API_DEBUG_PORT`
- `api.logLevel` → `API_LOG_LEVEL`
- `frontend.host` → `FRONTEND_HOST`
- `frontend.port` → `FRONTEND_PORT`
- `frontend.apiUrl` → `VITE_API_URL`
- `redis.host` → `REDIS_HOST`
- `redis.port` → `REDIS_PORT`
- `environment` → `ENVIRONMENT`
- `nodeEnv` → `NODE_ENV`

## Files to Modify

### 1. `package.json`
Add dependency and scripts:

```json
{
  "scripts": {
    "config:load": "node scripts/load-config.js",
    "config:validate": "node scripts/load-config.js --validate-only"
  },
  "devDependencies": {
    "js-yaml": "^4.1.0"
  }
}
```

### 2. `Makefile`
Load config at the start, before any other operations:

```makefile
# Load config and export variables
-include .config.env

# Or if include doesn't work well, use eval:
# $(eval $(shell node scripts/load-config.js --format shell-export))

# Remove the old .env include:
# -include .env  # REMOVE THIS LINE

# Update the dev target to ensure config is loaded:
dev: install-prereqs validate
	@node scripts/load-config.js  # Ensure config is loaded first
	@echo "========================================"
	# ... rest of dev target
```

**Changes:**
- Remove `-include .env` line
- Add config loading at the start
- Ensure `make dev` calls config loader before proceeding

### 3. `scripts/prepare-manifests.sh`
Source config before processing manifests:

```bash
#!/bin/bash
set -e

# Load config and export variables
eval $(node scripts/load-config.js --format shell-export)

NODE_ENV=${NODE_ENV:-development}
WORKSPACE_PATH=${WORKSPACE_PATH:-$(pwd)}

# Rest of script continues as before, using exported variables
```

**Changes:**
- Add config loading at the start
- Remove any hardcoded default values (use config instead)

### 4. `infra/k8s/configmap.yaml`
Replace hardcoded values with envsubst variables:

```yaml
# ConfigMap for Wander application environment variables
# Variables are populated from config.yaml via prepare-manifests.sh
apiVersion: v1
kind: ConfigMap
metadata:
  name: wander-config
  namespace: wander-dev
data:
  DATABASE_HOST: ${DATABASE_HOST}
  DATABASE_PORT: "${DATABASE_PORT}"
  DATABASE_NAME: ${DATABASE_NAME}
  DATABASE_USER: ${DATABASE_USER}
  DATABASE_PASSWORD: ${DATABASE_PASSWORD}
  DATABASE_POOL_SIZE: "${DATABASE_POOL_SIZE}"
  API_HOST: ${API_HOST}
  API_PORT: "${API_PORT}"
  API_DEBUG_PORT: "${API_DEBUG_PORT}"
  API_LOG_LEVEL: ${API_LOG_LEVEL}
  NODE_ENV: ${NODE_ENV}
  FRONTEND_HOST: ${FRONTEND_HOST}
  FRONTEND_PORT: "${FRONTEND_PORT}"
  VITE_API_URL: ${VITE_API_URL}
  REDIS_HOST: ${REDIS_HOST}
  REDIS_PORT: "${REDIS_PORT}"
  ENVIRONMENT: ${ENVIRONMENT}
```

**Changes:**
- Replace all hardcoded values with `${VAR}` placeholders
- These will be populated by `envsubst` in `prepare-manifests.sh` using exported variables from config loader

### 5. `.gitignore`
Add generated config files:

```
# Config files
config.local.yaml
.config.env
.env
```

**Changes:**
- Add `config.local.yaml` (local overrides, not committed)
- Add `.config.env` (generated shell exports)
- Ensure `.env` is already there (generated from config)

## Files to Remove

### 1. `.env.example`
No longer needed - `config.yaml.example` replaces it.

**Note:** Check if any scripts reference `.env.example` and update them:
- `Makefile` line 41: `[ -f .env ] && echo "✓ .env file exists" || (echo "⚠ Creating .env from .env.example" && cp .env.example .env)`
  - Update to: `[ -f .env ] && echo "✓ .env file exists" || (echo "⚠ Generating .env from config.yaml" && node scripts/load-config.js)`
- `scripts/validate-system.sh` line 248: `run_test ".env.example exists" "[ -f .env.example ]"`
  - Update to: `run_test "config.yaml exists" "[ -f config.yaml ]"`

## Implementation Steps

1. **Add dependency:**
   - Run `npm install --save-dev js-yaml@^4.1.0` in root

2. **Create config files:**
   - Create `config.yaml` with current values from `infra/k8s/configmap.yaml`
   - Create `config.yaml.example` as template with comments
   - Create `scripts/load-config.js` with full implementation

3. **Update package.json:**
   - Add `js-yaml` to `devDependencies`
   - Add `config:load` and `config:validate` scripts

4. **Update Makefile:**
   - Remove `-include .env` line
   - Add config loading at start
   - Update `.env` creation logic to use config loader
   - Ensure config is loaded before any commands that need env vars

5. **Update prepare-manifests.sh:**
   - Add config loading at start
   - Remove hardcoded defaults (use config values)

6. **Update configmap.yaml:**
   - Replace hardcoded values with `${VAR}` placeholders

7. **Update .gitignore:**
   - Add `config.local.yaml` and `.config.env`

8. **Update validation script:**
   - Replace `.env.example` check with `config.yaml` check

9. **Remove .env.example:**
   - Delete the file
   - Update any references

10. **Test:**
    - Run `npm run config:validate` to test validation
    - Run `npm run config:load` to generate files
    - Run `make dev` to ensure everything works
    - Verify services can read environment variables correctly

## Testing Checklist

- [ ] Config loader validates required fields
- [ ] Config loader validates types (ports, URLs, etc.)
- [ ] Config loader resolves `${VAR}` placeholders
- [ ] Config loader merges `config.local.yaml` correctly
- [ ] Config loader selects correct environment from `NODE_ENV`
- [ ] Generated `.env` file is correct format
- [ ] Generated `.config.env` exports variables correctly
- [ ] Makefile loads config and exports variables
- [ ] `prepare-manifests.sh` uses config values
- [ ] ConfigMap is generated with correct values
- [ ] Services can read environment variables (no code changes needed)
- [ ] Local development works with generated `.env`
- [ ] Kubernetes deployment works with ConfigMap
- [ ] Error messages are clear and actionable

## Migration Notes

- Existing `.env` files will be overwritten by config loader
- Users should migrate their local overrides to `config.local.yaml`
- No changes needed to service code (API, frontend)
- All environment variables remain the same names (backward compatible)

## Benefits

- **Cross-platform:** Works on Windows, macOS, Linux
- **Single source of truth:** All config in one YAML file
- **Environment-specific:** Easy overrides per environment
- **Validation:** Catches errors early with clear messages
- **No service changes:** Existing code continues to work
- **Developer experience:** YAML with comments is more readable than `.env`


#!/usr/bin/env node

/**
 * Config Loader for Wander Application
 * 
 * Loads config.yaml, merges with config.local.yaml if present,
 * selects environment, validates, and generates output files.
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Configuration
const CONFIG_FILE = path.join(__dirname, '..', 'config.yaml');
const LOCAL_CONFIG_FILE = path.join(__dirname, '..', 'config.local.yaml');
const ENV_FILE = path.join(__dirname, '..', '.env');
const CONFIG_ENV_FILE = path.join(__dirname, '..', '.config.env');

// Get command line arguments
const args = process.argv.slice(2);
const format = args.includes('--format') 
  ? args[args.indexOf('--format') + 1] 
  : 'all';
const validateOnly = args.includes('--validate-only');

// Get environment
const nodeEnv = process.env.NODE_ENV || 'development';

/**
 * Deep merge two objects
 */
function deepMerge(target, source) {
  const output = { ...target };
  if (isObject(target) && isObject(source)) {
    Object.keys(source).forEach(key => {
      if (isObject(source[key])) {
        if (!(key in target)) {
          Object.assign(output, { [key]: source[key] });
        } else {
          output[key] = deepMerge(target[key], source[key]);
        }
      } else {
        Object.assign(output, { [key]: source[key] });
      }
    });
  }
  return output;
}

function isObject(item) {
  return item && typeof item === 'object' && !Array.isArray(item);
}

/**
 * Flatten nested object to flat key-value pairs
 */
function flatten(obj, prefix = '', result = {}) {
  for (const key in obj) {
    if (obj.hasOwnProperty(key)) {
      const newKey = prefix ? `${prefix}_${key.toUpperCase()}` : key.toUpperCase();
      if (typeof obj[key] === 'object' && obj[key] !== null && !Array.isArray(obj[key])) {
        flatten(obj[key], newKey, result);
      } else {
        result[newKey] = obj[key];
      }
    }
  }
  return result;
}

/**
 * Resolve ${VAR} placeholders from environment variables
 */
function resolveEnvVars(value) {
  if (typeof value !== 'string') {
    return value;
  }
  
  return value.replace(/\$\{([^}]+)\}/g, (match, varName) => {
    const envValue = process.env[varName];
    if (envValue === undefined) {
      throw new Error(`Environment variable ${varName} is required but not set (used in config)`);
    }
    return envValue;
  });
}

/**
 * Recursively resolve environment variables in object
 */
function resolveEnvVarsInObject(obj) {
  if (typeof obj === 'string') {
    return resolveEnvVars(obj);
  }
  if (Array.isArray(obj)) {
    return obj.map(item => resolveEnvVarsInObject(item));
  }
  if (obj && typeof obj === 'object') {
    const result = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        result[key] = resolveEnvVarsInObject(obj[key]);
      }
    }
    return result;
  }
  return obj;
}

/**
 * Validate required fields
 */
function validateRequired(config) {
  const required = [
    'database.host',
    'database.port',
    'database.name',
    'database.user',
    'database.password',
    'api.host',
    'api.port',
    'frontend.host',
    'frontend.port',
    'frontend.apiUrl',
    'redis.host',
    'redis.port',
    'environment',
    'nodeEnv'
  ];

  const missing = [];
  for (const field of required) {
    const keys = field.split('.');
    let value = config;
    for (const key of keys) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        missing.push(field);
        break;
      }
    }
  }

  if (missing.length > 0) {
    throw new Error(`Missing required fields: ${missing.join(', ')}`);
  }
}

/**
 * Validate types and values
 */
function validateTypes(config) {
  const errors = [];

  // Validate ports (must be integers 1-65535)
  const portFields = [
    { path: 'database.port', value: config.database?.port },
    { path: 'api.port', value: config.api?.port },
    { path: 'api.debugPort', value: config.api?.debugPort },
    { path: 'frontend.port', value: config.frontend?.port },
    { path: 'redis.port', value: config.redis?.port }
  ];

  for (const { path: fieldPath, value } of portFields) {
    if (value !== undefined) {
      const port = parseInt(value, 10);
      if (isNaN(port) || port < 1 || port > 65535) {
        errors.push(`Invalid port value for ${fieldPath}: must be 1-65535, got "${value}"`);
      }
    }
  }

  // Validate log level
  const validLogLevels = ['debug', 'info', 'warn', 'error'];
  if (config.api?.logLevel && !validLogLevels.includes(config.api.logLevel)) {
    errors.push(`Invalid log level for api.logLevel: must be one of ${validLogLevels.join(', ')}, got "${config.api.logLevel}"`);
  }

  // Validate URL format
  if (config.frontend?.apiUrl) {
    try {
      new URL(config.frontend.apiUrl);
    } catch (e) {
      errors.push(`Invalid URL format for frontend.apiUrl: "${config.frontend.apiUrl}"`);
    }
  }

  // Validate pool size
  if (config.database?.poolSize !== undefined) {
    const poolSize = parseInt(config.database.poolSize, 10);
    if (isNaN(poolSize) || poolSize < 1) {
      errors.push(`Invalid pool size for database.poolSize: must be positive integer, got "${config.database.poolSize}"`);
    }
  }

  if (errors.length > 0) {
    throw new Error(`Validation errors:\n${errors.map(e => `  - ${e}`).join('\n')}`);
  }
}

/**
 * Load and process configuration
 */
function loadConfig() {
  // Check if config.yaml exists
  if (!fs.existsSync(CONFIG_FILE)) {
    throw new Error(`config.yaml not found. Please create it from config.yaml.example`);
  }

  // Load main config
  let config;
  try {
    const configContent = fs.readFileSync(CONFIG_FILE, 'utf8');
    config = yaml.load(configContent);
  } catch (e) {
    if (e.name === 'YAMLException') {
      throw new Error(`Invalid YAML in config.yaml: ${e.message}`);
    }
    throw e;
  }

  if (!config || !config.defaults) {
    throw new Error('config.yaml must have a "defaults" section');
  }

  // Merge with local config if present
  if (fs.existsSync(LOCAL_CONFIG_FILE)) {
    try {
      const localContent = fs.readFileSync(LOCAL_CONFIG_FILE, 'utf8');
      const localConfig = yaml.load(localContent);
      if (localConfig && localConfig.defaults) {
        config.defaults = deepMerge(config.defaults, localConfig.defaults);
      }
    } catch (e) {
      throw new Error(`Error loading config.local.yaml: ${e.message}`);
    }
  }

  // Select environment
  const envConfig = config.environments?.[nodeEnv] || {};
  const finalConfig = deepMerge(config.defaults, envConfig);

  // Resolve environment variables
  const resolvedConfig = resolveEnvVarsInObject(finalConfig);

  // Validate
  validateRequired(resolvedConfig);
  validateTypes(resolvedConfig);

  return resolvedConfig;
}

/**
 * Generate environment variable mapping
 */
function generateEnvVars(config) {
  // Map nested structure to flat env vars
  const mapping = {
    'database.host': 'DATABASE_HOST',
    'database.port': 'DATABASE_PORT',
    'database.name': 'DATABASE_NAME',
    'database.user': 'DATABASE_USER',
    'database.password': 'DATABASE_PASSWORD',
    'database.poolSize': 'DATABASE_POOL_SIZE',
    'api.host': 'API_HOST',
    'api.port': 'API_PORT',
    'api.debugPort': 'API_DEBUG_PORT',
    'api.logLevel': 'API_LOG_LEVEL',
    'frontend.host': 'FRONTEND_HOST',
    'frontend.port': 'FRONTEND_PORT',
    'frontend.apiUrl': 'VITE_API_URL',
    'redis.host': 'REDIS_HOST',
    'redis.port': 'REDIS_PORT',
    'environment': 'ENVIRONMENT',
    'nodeEnv': 'NODE_ENV'
  };

  const envVars = {};
  for (const [configPath, envName] of Object.entries(mapping)) {
    const keys = configPath.split('.');
    let value = config;
    for (const key of keys) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        value = undefined;
        break;
      }
    }
    if (value !== undefined) {
      envVars[envName] = String(value);
    }
  }

  return envVars;
}

/**
 * Generate .env file
 */
function generateEnvFile(envVars) {
  const lines = Object.entries(envVars)
    .map(([key, value]) => `${key}=${value}`)
    .join('\n');
  fs.writeFileSync(ENV_FILE, lines + '\n', 'utf8');
}

/**
 * Generate .config.env file (shell exports)
 */
function generateConfigEnvFile(envVars) {
  const lines = Object.entries(envVars)
    .map(([key, value]) => `export ${key}="${value}"`)
    .join('\n');
  fs.writeFileSync(CONFIG_ENV_FILE, lines + '\n', 'utf8');
}

/**
 * Generate shell export output
 */
function generateShellExport(envVars) {
  return Object.entries(envVars)
    .map(([key, value]) => `export ${key}="${value}"`)
    .join('\n');
}

/**
 * Generate ConfigMap data output
 */
function generateConfigMap(envVars) {
  const lines = Object.entries(envVars)
    .map(([key, value]) => `  ${key}: "${value}"`)
    .join('\n');
  return `data:\n${lines}`;
}

/**
 * Generate JSON output
 */
function generateJSON(envVars) {
  return JSON.stringify(envVars, null, 2);
}

/**
 * Main execution
 */
function main() {
  try {
    const config = loadConfig();

    if (validateOnly) {
      console.log('✓ Configuration is valid');
      process.exit(0);
    }

    const envVars = generateEnvVars(config);

    // Generate output based on format
    switch (format) {
      case 'env':
        generateEnvFile(envVars);
        console.log(`✓ Generated ${ENV_FILE}`);
        break;
      
      case 'shell-export':
        generateConfigEnvFile(envVars);
        console.error(`✓ Generated ${CONFIG_ENV_FILE}`);
        // Output to stdout for eval (stderr for messages)
        console.log(generateShellExport(envVars));
        break;
      
      case 'configmap':
        console.log(generateConfigMap(envVars));
        break;
      
      case 'json':
        console.log(generateJSON(envVars));
        break;
      
      case 'all':
      default:
        generateEnvFile(envVars);
        generateConfigEnvFile(envVars);
        console.log(`✓ Generated ${ENV_FILE}`);
        console.log(`✓ Generated ${CONFIG_ENV_FILE}`);
        break;
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

main();


#!/usr/bin/env node

/**
 * Config Editor Server for Wander Application
 * 
 * Serves a web-based configuration editor that allows users to edit
 * config.yaml or config.local.yaml through a visual form interface.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const { spawn } = require('child_process');

// Configuration
const CONFIG_FILE = path.join(__dirname, '..', 'config.yaml');
const LOCAL_CONFIG_FILE = path.join(__dirname, '..', 'config.local.yaml');
const CONFIG_EXAMPLE_FILE = path.join(__dirname, '..', 'config.yaml.example');
const HTML_FILE = path.join(__dirname, 'config-editor.html');
const START_PORT = 8888;
const MAX_PORT_ATTEMPTS = 10;
const TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes

let server;
let timeoutId;
let targetFile = CONFIG_FILE; // Which file to edit

/**
 * Check if port is in use
 */
function isPortInUse(port) {
  return new Promise((resolve) => {
    const testServer = http.createServer();
    testServer.listen(port, () => {
      testServer.once('close', () => resolve(false));
      testServer.close();
    });
    testServer.on('error', () => resolve(true));
  });
}

/**
 * Find available port
 */
async function findAvailablePort() {
  let port = START_PORT;
  for (let i = 0; i < MAX_PORT_ATTEMPTS; i++) {
    const inUse = await isPortInUse(port);
    if (!inUse) {
      return port;
    }
    port++;
  }
  throw new Error(`Could not find available port (tried ${START_PORT}-${START_PORT + MAX_PORT_ATTEMPTS - 1})`);
}

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
 * Load config file
 */
function loadConfig(filePath) {
  if (!fs.existsSync(filePath)) {
    return null;
  }
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    return yaml.load(content);
  } catch (e) {
    throw new Error(`Failed to load ${filePath}: ${e.message}`);
  }
}

/**
 * Save config file
 */
function saveConfig(filePath, config) {
  try {
    const yamlContent = yaml.dump(config, {
      indent: 2,
      lineWidth: -1,
      quotingType: '"',
    });
    fs.writeFileSync(filePath, yamlContent, 'utf8');
    return true;
  } catch (e) {
    throw new Error(`Failed to save ${filePath}: ${e.message}`);
  }
}

/**
 * Create default config from example
 */
function createDefaultConfig() {
  if (fs.existsSync(CONFIG_EXAMPLE_FILE)) {
    return loadConfig(CONFIG_EXAMPLE_FILE);
  }
  // Fallback defaults
  return {
    defaults: {
      database: {
        host: 'postgres',
        port: 5432,
        name: 'wander_dev',
        user: 'postgres',
        password: 'dev_password',
        poolSize: 10
      },
      api: {
        host: '0.0.0.0',
        port: 4000,
        debugPort: 9229,
        logLevel: 'debug'
      },
      frontend: {
        host: '0.0.0.0',
        port: 3000,
        apiUrl: 'http://localhost:4000'
      },
      redis: {
        host: 'redis',
        port: 6379
      },
      environment: 'development',
      nodeEnv: 'development'
    },
    environments: {
      development: {},
      production: {
        database: {
          name: 'wander_prod',
          password: '${DATABASE_PASSWORD}'
        },
        api: {
          logLevel: 'info'
        },
        environment: 'production',
        nodeEnv: 'production'
      }
    }
  };
}

/**
 * Open browser
 */
function openBrowser(url) {
  const platform = process.platform;
  let command;
  
  if (platform === 'darwin') {
    command = 'open';
  } else if (platform === 'linux') {
    command = 'xdg-open';
  } else if (platform === 'win32') {
    command = 'start';
  } else {
    return false;
  }
  
  try {
    spawn(command, [url], { detached: true, stdio: 'ignore' });
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Start timeout
 */
function startTimeout() {
  timeoutId = setTimeout(() => {
    console.error('⏱️  Timeout: No configuration saved. Continuing with existing config...');
    process.exit(0);
  }, TIMEOUT_MS);
}

/**
 * Stop timeout
 */
function stopTimeout() {
  if (timeoutId) {
    clearTimeout(timeoutId);
    timeoutId = null;
  }
}

/**
 * Handle request
 */
function handleRequest(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);
  
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  // API: Get config
  if (req.method === 'GET' && url.pathname === '/api/config') {
    try {
      // Determine which file to edit
      const hasLocal = fs.existsSync(LOCAL_CONFIG_FILE);
      const config = loadConfig(targetFile) || createDefaultConfig();
      
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        config,
        targetFile: path.basename(targetFile),
        hasLocal,
        editingLocal: targetFile === LOCAL_CONFIG_FILE
      }));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: e.message }));
    }
    return;
  }
  
  // API: Save config
  if (req.method === 'POST' && url.pathname === '/api/config') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const { config, targetFile: newTargetFile } = data;
        
        // Update target file if specified
        if (newTargetFile) {
          targetFile = newTargetFile === 'config.local.yaml' 
            ? LOCAL_CONFIG_FILE 
            : CONFIG_FILE;
        }
        
        // Ensure target file directory exists
        const dir = path.dirname(targetFile);
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }
        
        // Load existing config and merge with new config
        // This preserves any fields not in the form data
        const existingConfig = loadConfig(targetFile);
        const mergedConfig = existingConfig 
          ? deepMerge(existingConfig, config)
          : config;
        
        // Save merged config
        saveConfig(targetFile, mergedConfig);
        
        // Also ensure config.yaml exists (merge with local if needed)
        // This ensures config.yaml is always up to date
        if (targetFile === LOCAL_CONFIG_FILE && fs.existsSync(CONFIG_FILE)) {
          // If saving local, we keep both files separate
          // But if user wants to update main config, they can switch files
        } else if (targetFile === CONFIG_FILE) {
          // Saving main config - ensure it's properly formatted
          // Config is already saved above
        }
        
        stopTimeout();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, message: 'Configuration saved successfully' }));
        
        // Exit after a short delay to allow response to be sent
        // This pauses the Makefile execution until save is complete
        setTimeout(() => {
          process.exit(0);
        }, 500);
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }
  
  // Serve HTML file
  if (req.method === 'GET' && (url.pathname === '/' || url.pathname === '/index.html')) {
    if (!fs.existsSync(HTML_FILE)) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Config editor HTML file not found');
      return;
    }
    
    const html = fs.readFileSync(HTML_FILE, 'utf8');
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(html);
    return;
  }
  
  // 404
  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not found');
}

/**
 * Main
 */
async function main() {
  try {
    // Determine which file to edit (prefer local if exists)
    if (fs.existsSync(LOCAL_CONFIG_FILE)) {
      targetFile = LOCAL_CONFIG_FILE;
    } else if (!fs.existsSync(CONFIG_FILE)) {
      // Create default config if neither exists
      const defaultConfig = createDefaultConfig();
      saveConfig(CONFIG_FILE, defaultConfig);
    }
    
    // Find available port
    const port = await findAvailablePort();
    
    // Create server
    server = http.createServer(handleRequest);
    
    server.listen(port, () => {
      const url = `http://localhost:${port}`;
      console.log(`📝 Configuration editor: ${url}`);
      
      // Try to open browser
      if (!openBrowser(url)) {
        console.log(`   (Open this URL in your browser manually)`);
      }
      
      // Start timeout
      startTimeout();
    });
    
    server.on('error', (err) => {
      console.error(`❌ Server error: ${err.message}`);
      process.exit(1);
    });
    
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  stopTimeout();
  if (server) {
    server.close();
  }
  process.exit(0);
});

process.on('SIGTERM', () => {
  stopTimeout();
  if (server) {
    server.close();
  }
  process.exit(0);
});

main();


import { Router } from 'express';
import { getDatabase } from '../database/connection';
import { getRedis } from '../database/redis';

export const healthRouter = Router();

// Basic health check
healthRouter.get('/', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Detailed readiness check
healthRouter.get('/ready', async (req, res) => {
  const checks = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    services: {
      database: 'unknown',
      redis: 'unknown',
    },
  };

  // Check database
  try {
    const db = getDatabase();
    await db.raw('SELECT 1');
    checks.services.database = 'connected';
  } catch (error) {
    checks.services.database = 'disconnected';
    checks.status = 'degraded';
  }

  // Check Redis
  try {
    const redis = getRedis();
    await redis.ping();
    checks.services.redis = 'connected';
  } catch (error) {
    checks.services.redis = 'disconnected';
    checks.status = 'degraded';
  }

  const statusCode = checks.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(checks);
});

// Liveness check (always returns OK if server is running)
healthRouter.get('/live', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});


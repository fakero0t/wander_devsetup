import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { healthRouter } from './routes/health';
import { errorHandler } from './middleware/errorHandler';
import { connectDatabase } from './database/connection';
import { connectRedis } from './database/redis';

const app = express();
const PORT = process.env.API_PORT || 4000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/health', healthRouter);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Wander API',
    version: '1.0.0',
    status: 'running'
  });
});

// Error handling
app.use(errorHandler);

// Initialize connections and start server
async function start() {
  try {
    // Connect to database
    await connectDatabase();
    console.log('✓ Database connected');

    // Connect to Redis
    await connectRedis();
    console.log('✓ Redis connected');

    // Start server
    app.listen(PORT, () => {
      console.log(`✓ API server running on port ${PORT}`);
      console.log(`  Health check: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully...');
  process.exit(0);
});

start();


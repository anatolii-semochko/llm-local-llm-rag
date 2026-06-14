import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env, isDevelopment } from './config/environment';
import { requestLoggerMiddleware } from './middleware/requestLogger';
import { authMiddleware } from './middleware/auth';
import { OllamaService } from './services/ollamaService';
import { ChatController } from './controllers/chatController';
import { EmbeddingController } from './controllers/embeddingController';
import { ModelController } from './controllers/modelController';
import logger from './utils/logger';
import { ApiError } from './types/api';

const app = express();

// Security middleware
app.use(helmet());
app.use(cors());

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use(requestLoggerMiddleware as any);

// Initialize services and controllers
const ollamaService = new OllamaService();
const chatController = new ChatController(ollamaService);
const embeddingController = new EmbeddingController(ollamaService);
const modelController = new ModelController(ollamaService);

// Health check endpoint (no auth required)
app.get('/health', (req: any, res) => modelController.healthCheck(req, res));

// Authentication middleware for API endpoints
app.use('/v1', authMiddleware as any);

// OpenAI-compatible API routes
app.post('/v1/chat/completions', (req: any, res) =>
  chatController.createChatCompletion(req, res)
);

app.post('/v1/embeddings', (req: any, res) =>
  embeddingController.createEmbedding(req, res)
);

app.get('/v1/models', (req: any, res) =>
  modelController.getModels(req, res)
);

app.get('/v1/models/:model', (req: any, res) =>
  modelController.getModel(req, res)
);

// 404 handler
app.use('*', (req, res) => {
  const error: ApiError = {
    error: {
      message: `The requested endpoint (${req.method} ${req.originalUrl}) does not exist.`,
      type: 'invalid_request_error',
      code: 'not_found'
    }
  };
  res.status(404).json(error);
});

// Global error handler
app.use((error: Error, req: any, res: any, next: any) => {
  logger.error('Unhandled error', {
    requestId: req.requestId,
    error: error.message,
    stack: error.stack
  });

  const apiError: ApiError = {
    error: {
      message: isDevelopment ? error.message : 'Internal server error',
      type: 'server_error',
      code: 'internal_error'
    }
  };

  res.status(500).json(apiError);
});

// Start server
const server = app.listen(env.PORT, () => {
  logger.info(`🚀 Local LLM Service started on port ${env.PORT}`);
  logger.info(`📍 Base URL: http://localhost:${env.PORT}`);
  logger.info(`🔗 OpenAI API: http://localhost:${env.PORT}/v1`);
  logger.info(`💊 Health check: http://localhost:${env.PORT}/health`);
  logger.info(`🌍 Environment: ${env.NODE_ENV}`);

  if (isDevelopment) {
    logger.info('📋 Available models will be listed at /v1/models');
    logger.info('🔑 Remember to set your API_KEY in .env file');
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

export default app;
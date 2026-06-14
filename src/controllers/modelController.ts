import { Response } from 'express';
import { OllamaService } from '../services/ollamaService';
import { RequestWithId } from '../middleware/requestLogger';
import { ApiError } from '../types/api';
import { logError } from '../utils/logger';

export class ModelController {
  constructor(private ollamaService: OllamaService) {}

  async getModels(req: RequestWithId, res: Response): Promise<void> {
    try {
      const response = await this.ollamaService.getModels(req.requestId);
      res.json(response);
    } catch (error) {
      logError(req.requestId, error as Error);

      const apiError: ApiError = {
        error: {
          message: (error as Error).message || 'Failed to fetch models',
          type: 'server_error',
          code: 'internal_error'
        }
      };

      res.status(500).json(apiError);
    }
  }

  async getModel(req: RequestWithId, res: Response): Promise<void> {
    try {
      const { model } = req.params;

      if (!model) {
        const error: ApiError = {
          error: {
            message: 'Model parameter is required',
            type: 'invalid_request_error',
            param: 'model',
            code: 'invalid_request'
          }
        };
        res.status(400).json(error);
        return;
      }

      const modelsResponse = await this.ollamaService.getModels(req.requestId);
      const foundModel = modelsResponse.data.find(m => m.id === model);

      if (!foundModel) {
        const error: ApiError = {
          error: {
            message: `The model '${model}' does not exist`,
            type: 'invalid_request_error',
            param: 'model',
            code: 'model_not_found'
          }
        };
        res.status(404).json(error);
        return;
      }

      res.json(foundModel);
    } catch (error) {
      logError(req.requestId, error as Error);

      const apiError: ApiError = {
        error: {
          message: (error as Error).message || 'Failed to fetch model',
          type: 'server_error',
          code: 'internal_error'
        }
      };

      res.status(500).json(apiError);
    }
  }

  async healthCheck(req: RequestWithId, res: Response): Promise<void> {
    try {
      const isHealthy = await this.ollamaService.healthCheck(req.requestId);

      if (isHealthy) {
        res.json({
          status: 'ok',
          timestamp: new Date().toISOString(),
          service: 'ollama',
          uptime: process.uptime()
        });
      } else {
        res.status(503).json({
          status: 'error',
          timestamp: new Date().toISOString(),
          service: 'ollama',
          message: 'Ollama service is not available'
        });
      }
    } catch (error) {
      logError(req.requestId, error as Error);

      res.status(503).json({
        status: 'error',
        timestamp: new Date().toISOString(),
        service: 'ollama',
        message: (error as Error).message || 'Health check failed'
      });
    }
  }
}
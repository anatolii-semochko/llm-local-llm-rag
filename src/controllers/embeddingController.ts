import { Request, Response } from 'express';
import { z } from 'zod';
import { OllamaService } from '../services/ollamaService';
import { RequestWithId } from '../middleware/requestLogger';
import { EmbeddingRequest, ApiError } from '../types/api';
import { env } from '../config/environment';
import { logError } from '../utils/logger';

const embeddingSchema = z.object({
  model: z.string().min(1),
  input: z.union([z.string(), z.array(z.string())]),
  encoding_format: z.enum(['float', 'base64']).optional().default('float')
});

export class EmbeddingController {
  constructor(private ollamaService: OllamaService) {}

  async createEmbedding(req: RequestWithId, res: Response): Promise<void> {
    try {
      const validation = embeddingSchema.safeParse(req.body);

      if (!validation.success) {
        const error: ApiError = {
          error: {
            message: `Invalid request: ${validation.error.errors.map(e => e.message).join(', ')}`,
            type: 'invalid_request_error',
            param: validation.error.errors[0]?.path.join('.') || null,
            code: 'invalid_request'
          }
        };
        res.status(400).json(error);
        return;
      }

      const request: EmbeddingRequest = {
        ...validation.data,
        model: validation.data.model || env.DEFAULT_EMBEDDING_MODEL
      };

      // Validate input length for arrays
      if (Array.isArray(request.input)) {
        if (request.input.length === 0) {
          const error: ApiError = {
            error: {
              message: 'Input array cannot be empty',
              type: 'invalid_request_error',
              param: 'input',
              code: 'invalid_request'
            }
          };
          res.status(400).json(error);
          return;
        }

        if (request.input.length > 2048) {
          const error: ApiError = {
            error: {
              message: 'Input array too large (max 2048 items)',
              type: 'invalid_request_error',
              param: 'input',
              code: 'invalid_request'
            }
          };
          res.status(400).json(error);
          return;
        }
      }

      const response = await this.ollamaService.getEmbedding(req.requestId, request);
      res.json(response);

    } catch (error) {
      logError(req.requestId, error as Error);

      const apiError: ApiError = {
        error: {
          message: (error as Error).message || 'Internal server error',
          type: 'server_error',
          code: 'internal_error'
        }
      };

      if ((error as Error).message.includes('model not found')) {
        apiError.error.type = 'invalid_request_error';
        apiError.error.code = 'model_not_found';
        res.status(404).json(apiError);
      } else {
        res.status(500).json(apiError);
      }
    }
  }
}
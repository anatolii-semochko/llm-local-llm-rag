import { Request, Response } from 'express';
import { z } from 'zod';
import { OllamaService } from '../services/ollamaService';
import { RequestWithId } from '../middleware/requestLogger';
import { ChatCompletionRequest, ApiError } from '../types/api';
import { env } from '../config/environment';
import { logError } from '../utils/logger';

const chatCompletionSchema = z.object({
  model: z.string().min(1),
  messages: z.array(z.object({
    role: z.enum(['user', 'assistant', 'system']),
    content: z.string()
  })).min(1),
  max_tokens: z.number().positive().optional(),
  temperature: z.number().min(0).max(2).optional(),
  top_p: z.number().min(0).max(1).optional(),
  stream: z.boolean().optional().default(false)
});

export class ChatController {
  constructor(private ollamaService: OllamaService) {}

  async createChatCompletion(req: RequestWithId, res: Response): Promise<void> {
    try {
      const validation = chatCompletionSchema.safeParse(req.body);

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

      const request: ChatCompletionRequest = {
        ...validation.data,
        model: validation.data.model || env.DEFAULT_CHAT_MODEL
      };

      if (request.stream) {
        const error: ApiError = {
          error: {
            message: 'Streaming is not supported in this implementation',
            type: 'invalid_request_error',
            param: 'stream',
            code: 'feature_not_supported'
          }
        };
        res.status(400).json(error);
        return;
      }

      const response = await this.ollamaService.getChatCompletion(req.requestId, request);
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
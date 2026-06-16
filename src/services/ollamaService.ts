import OpenAI from 'openai';
import { env } from '../config/environment';
import {
  ChatCompletionRequest,
  ChatCompletionResponse,
  EmbeddingRequest,
  EmbeddingResponse,
  ModelsResponse
} from '../types/api';
import { logLLMRequest, logLLMResponse, logError } from '../utils/logger';

export class OllamaService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({
      apiKey: 'ollama',
      baseURL: `${env.OLLAMA_BASE_URL}/v1`,
      timeout: 30 * 60 * 1000,
    });
  }

  async getChatCompletion(
    requestId: string,
    request: ChatCompletionRequest
  ): Promise<ChatCompletionResponse> {
    try {
      const prompt = this.formatMessages(request.messages);
      logLLMRequest(requestId, request.model, prompt);

      const createParams: any = {
        model: request.model,
        messages: request.messages,
        stream: false,
        think: false,
      };

      if (request.max_tokens !== undefined) {
        createParams.max_tokens = request.max_tokens;
      }
      if (request.temperature !== undefined) {
        createParams.temperature = request.temperature;
      }
      if (request.top_p !== undefined) {
        createParams.top_p = request.top_p;
      }

      const response = await this.client.chat.completions.create(createParams);

      // Process response to ensure OpenAI compatibility
      if (response.choices && response.choices[0]) {
        const choice = response.choices[0];
        const message = choice.message as any;

        // Get actual response content (prefer reasoning over content for qwen models)
        const actualContent = message?.reasoning || message?.content || '';

        // Standardize to OpenAI format - only content field
        message.content = actualContent;

        // Remove non-standard fields for OpenAI compatibility
        if (message.reasoning) {
          delete message.reasoning;
        }

        logLLMResponse(
          requestId,
          request.model,
          actualContent.length,
          response.usage?.total_tokens,
          actualContent
        );
      }

      return response as ChatCompletionResponse;
    } catch (error) {
      logError(requestId, error as Error, { model: request.model });
      throw new Error(`Ollama chat completion failed: ${(error as Error).message}`);
    }
  }

  async getEmbedding(
    requestId: string,
    request: EmbeddingRequest
  ): Promise<EmbeddingResponse> {
    try {
      const input = Array.isArray(request.input)
        ? request.input.join(' ')
        : request.input;

      logLLMRequest(requestId, request.model, `Embedding for: ${input.substring(0, 100)}...`);

      const embedParams: any = {
        model: request.model,
        input: request.input
      };

      if (request.encoding_format !== undefined) {
        embedParams.encoding_format = request.encoding_format;
      }

      const response = await this.client.embeddings.create(embedParams);

      logLLMResponse(
        requestId,
        request.model,
        response.data.length,
        response.usage.total_tokens
      );

      return response as EmbeddingResponse;
    } catch (error) {
      logError(requestId, error as Error, { model: request.model });
      throw new Error(`Ollama embedding failed: ${(error as Error).message}`);
    }
  }

  async getModels(requestId: string): Promise<ModelsResponse> {
    try {
      const response = await this.client.models.list();

      const modelsResponse: ModelsResponse = {
        object: 'list',
        data: response.data.map(model => ({
          id: model.id,
          object: 'model',
          created: model.created || Math.floor(Date.now() / 1000),
          owned_by: 'ollama',
          permission: [{
            id: `modelperm-${model.id}`,
            object: 'model_permission',
            created: Math.floor(Date.now() / 1000),
            allow_create_engine: false,
            allow_sampling: true,
            allow_logprobs: true,
            allow_search_indices: false,
            allow_view: true,
            allow_fine_tuning: false,
            organization: '*',
            group: null,
            is_blocking: false
          }]
        }))
      };

      return modelsResponse;
    } catch (error) {
      logError(requestId, error as Error);
      throw new Error(`Failed to fetch models: ${(error as Error).message}`);
    }
  }

  async healthCheck(requestId: string): Promise<boolean> {
    try {
      await this.client.models.list();
      return true;
    } catch (error) {
      logError(requestId, error as Error);
      return false;
    }
  }

  private formatMessages(messages: Array<{ role: string; content: string }>): string {
    return messages
      .map(msg => `${msg.role}: ${msg.content}`)
      .join('\n');
  }
}
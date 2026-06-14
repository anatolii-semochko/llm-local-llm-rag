import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('3000').transform(Number),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  API_KEY: z.string().min(1, 'API_KEY is required'),
  OLLAMA_HOST: z.string().default('localhost'),
  OLLAMA_PORT: z.string().default('11434').transform(Number),
  OLLAMA_BASE_URL: z.string().default('http://localhost:11434'),
  POSTGRES_HOST: z.string().default('localhost'),
  POSTGRES_PORT: z.string().default('5432').transform(Number),
  POSTGRES_USER: z.string().default('postgres'),
  POSTGRES_PASSWORD: z.string().default('postgres'),
  POSTGRES_DB: z.string().default('rag'),
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
  LOG_FILE: z.string().default('logs/app.log'),
  DEFAULT_CHAT_MODEL: z.string().default('qwen3:14b'),
  DEFAULT_EMBEDDING_MODEL: z.string().default('nomic-embed-text'),
});

export type Environment = z.infer<typeof envSchema>;

export const env = envSchema.parse(process.env);

export const isDevelopment = env.NODE_ENV === 'development';
export const isProduction = env.NODE_ENV === 'production';
export const isTest = env.NODE_ENV === 'test';
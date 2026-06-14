import winston from 'winston';
import chalk from 'chalk';
import { env } from '../config/environment';

const colors = {
  error: chalk.red.bold,
  warn: chalk.yellow.bold,
  info: chalk.blue.bold,
  debug: chalk.gray,
  success: chalk.green.bold,
  request: chalk.cyan,
  response: chalk.magenta,
};

const customFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.printf(({ timestamp, level, message, requestId, ...meta }) => {
    const colorFn = colors[level as keyof typeof colors] || chalk.white;
    const prefix = requestId ? `[${requestId}] ` : '';

    let logMessage = `${chalk.dim(timestamp)} ${colorFn(level.toUpperCase())} ${prefix}${message}`;

    if (Object.keys(meta).length > 0) {
      logMessage += `\n${chalk.dim(JSON.stringify(meta, null, 2))}`;
    }

    return logMessage;
  })
);

const consoleFormat = winston.format.combine(
  winston.format.timestamp({ format: 'HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, requestId, ...meta }) => {
    const colorFn = colors[level as keyof typeof colors] || chalk.white;
    const prefix = requestId ? chalk.dim(`[${requestId}] `) : '';

    let logMessage = `${chalk.dim(timestamp)} ${colorFn('●')} ${prefix}${message}`;

    if (Object.keys(meta).length > 0) {
      logMessage += `\n${chalk.dim(JSON.stringify(meta, null, 2))}`;
    }

    return logMessage;
  })
);

const logger = winston.createLogger({
  level: env.LOG_LEVEL,
  transports: [
    new winston.transports.File({
      filename: env.LOG_FILE,
      format: customFormat,
      maxsize: 10 * 1024 * 1024, // 10MB
      maxFiles: 5,
    }),
    new winston.transports.Console({
      format: consoleFormat,
      level: 'debug',
    }),
  ],
});

export const logRequestStart = (requestId: string, method: string, url: string, body?: any) => {
  logger.info('═══════════════════════════════════════════════════════════════════', { requestId });
  logger.info(colors.request(`${method} ${url}`), { requestId });
  if (body && Object.keys(body).length > 0) {
    logger.info('Request body:', { requestId, body });
  }
};

export const logRequestEnd = (requestId: string, statusCode: number, duration: number) => {
  const statusColor = statusCode >= 400 ? chalk.red : statusCode >= 300 ? chalk.yellow : chalk.green;
  logger.info(colors.response(`Response: ${statusColor(statusCode)} (${duration}ms)`), { requestId });
  logger.info('═══════════════════════════════════════════════════════════════════', { requestId });
};

export const logLLMRequest = (requestId: string, model: string, prompt: string) => {
  logger.info(colors.info(`LLM Request to ${model}`), {
    requestId,
    model,
    promptLength: prompt.length,
    promptPreview: prompt.substring(0, 100) + (prompt.length > 100 ? '...' : '')
  });
};

export const logLLMResponse = (requestId: string, model: string, responseLength: number, tokens?: number, content?: string) => {
  logger.info(colors.success(`LLM Response from ${model}`), {
    requestId,
    model,
    responseLength,
    tokens,
    responsePreview: content ? content.substring(0, 100) + (content.length > 100 ? '...' : '') : undefined
  });
};

export const logError = (requestId: string, error: Error, context?: any) => {
  logger.error('Error occurred', {
    requestId,
    error: error.message,
    stack: error.stack,
    context
  });
};

export default logger;
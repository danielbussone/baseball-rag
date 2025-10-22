import pino from 'pino';
import { env } from './env.js';

const isDevelopment = env.server.nodeEnv === 'development';

// Fastify-compatible logger configuration
export const loggerConfig = {
  level: process.env.LOG_LEVEL || (isDevelopment ? 'debug' : 'info'),

  // Pretty print in development
  transport: isDevelopment
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'HH:MM:ss',
          ignore: 'pid,hostname',
          singleLine: false,
        },
      }
    : undefined,

  // Redact sensitive data
  redact: {
    paths: ['req.headers.authorization', 'password', 'DB_PASSWORD'],
    remove: true,
  },

  // Serializers for request/response objects
  serializers: {
    res(reply: any) {
      return {
        statusCode: reply.statusCode,
      };
    },
    req(request: any) {
      return {
        method: request.method,
        url: request.url,
        path: request.routeOptions?.url,
        parameters: request.params,
        // Headers redacted by the redact config above
      };
    },
  },
};

// Standalone Pino logger instance for non-Fastify use
export const logger = pino({
  ...loggerConfig,
  // Base fields to include in every log
  base: {
    env: env.server.nodeEnv,
  },
});

// Child logger factory for different modules
export function createModuleLogger(module: string) {
  return logger.child({ module });
}

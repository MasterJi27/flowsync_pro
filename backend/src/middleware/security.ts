import { Request } from 'express';
import rateLimit from 'express-rate-limit';
import { env } from '../config/env';
import { logger } from '../config/logger';

const asErrorPayload = (code: string, message: string) => ({
  error: {
    code,
    message,
  },
});

const requestIp = (req: Request) => req.ip ?? req.socket.remoteAddress ?? 'unknown';

export const apiLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS,
  max: env.RATE_LIMIT_MAX_REQUESTS,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.path === '/health',
  handler: (req, res) => {
    logger.warn(
      {
        ip: requestIp(req),
        path: req.originalUrl,
        method: req.method,
      },
      'Global rate limit exceeded',
    );
    res
      .status(429)
      .json(asErrorPayload('TOO_MANY_REQUESTS', 'Too many requests. Please retry shortly.'));
  },
});

export const authLimiter = rateLimit({
  windowMs: env.AUTH_RATE_LIMIT_WINDOW_MS,
  max: env.AUTH_RATE_LIMIT_MAX_REQUESTS,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  handler: (req, res) => {
    logger.warn(
      {
        ip: requestIp(req),
        path: req.originalUrl,
        method: req.method,
      },
      'Authentication rate limit exceeded',
    );
    res
      .status(429)
      .json(
        asErrorPayload('AUTH_RATE_LIMITED', 'Too many authentication attempts. Try again later.'),
      );
  },
});

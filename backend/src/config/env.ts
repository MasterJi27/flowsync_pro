import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const trustProxySchema = z
  .preprocess((value) => {
    if (typeof value === 'string') {
      const normalized = value.trim().toLowerCase();
      return ['1', 'true', 'yes', 'on'].includes(normalized);
    }
    if (typeof value === 'number') {
      return value === 1;
    }
    return value;
  }, z.boolean())
  .default(false);

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(4000),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(24),
  JWT_EXPIRES_IN: z.string().default('8h'),
  INVITE_EXPIRES_HOURS: z.coerce.number().default(168),
  CORS_ORIGIN: z.string().default(''),
  TRUST_PROXY: trustProxySchema,
  RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60_000),
  RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(120),
  AUTH_RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(15 * 60_000),
  AUTH_RATE_LIMIT_MAX_REQUESTS: z.coerce.number().int().positive().default(25),
  OVERDUE_SWEEP_CRON: z.string().default('*/1 * * * *'),
  ESCALATION_STEP_MINUTES: z.coerce.number().default(5),
  FIREBASE_PROJECT_ID: z.string().optional(),
  FIREBASE_CLIENT_EMAIL: z.string().optional(),
  FIREBASE_PRIVATE_KEY: z.string().optional()
});

export const env = envSchema.parse(process.env);

const configuredOrigins = env.CORS_ORIGIN.split(',')
  .map((origin) => origin.trim())
  .filter((origin) => origin.length > 0);

const validCorsOrigins = configuredOrigins.filter((origin) => {
  if (origin === '*') {
    return false;
  }

  try {
    const parsed = new URL(origin);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
});

export const corsOrigins = validCorsOrigins.length > 0 ? validCorsOrigins : false;

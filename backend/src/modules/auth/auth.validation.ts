import { GlobalRole } from '@prisma/client';
import { z } from 'zod';

const roleSchema = z.preprocess(
  (value) => (typeof value === 'string' ? value.toUpperCase() : value),
  z.nativeEnum(GlobalRole)
);

export const registerSchema = z.object({
  body: z.object({
    name: z.string().min(2),
    phone: z.string().min(8).max(20),
    email: z.string().email(),
    password: z.string().min(8),
    globalRole: roleSchema.default(GlobalRole.CLIENT),
    inviteToken: z.string().optional()
  })
});

export const loginSchema = z.object({
  body: z.object({
    emailOrPhone: z.string().min(3),
    password: z.string().min(8)
  })
});

export const inviteAccessSchema = z.object({
  body: z.object({
    token: z.string().min(24),
    phone: z.string().min(8).max(20).optional()
  })
});

export const firebaseLoginSchema = z.object({
  body: z.object({
    idToken: z.string().min(20),
    email: z.string().email().optional(),
    phone: z.string().min(6).max(30).optional(),
    name: z.string().min(1).max(100).optional()
  })
});

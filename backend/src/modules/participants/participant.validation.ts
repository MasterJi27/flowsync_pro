import { ParticipantRole } from '@prisma/client';
import { z } from 'zod';

const roleSchema = z.preprocess(
  (value) => (typeof value === 'string' ? value.toUpperCase() : value),
  z.nativeEnum(ParticipantRole)
);

export const shipmentParticipantParams = z.object({
  params: z.object({
    id: z.string().uuid()
  })
});

export const addParticipantSchema = z.object({
  params: z.object({
    id: z.string().uuid()
  }),
  body: z.object({
    userId: z.string().uuid(),
    participantRole: roleSchema,
    permissions: z.record(z.boolean()).optional()
  })
});

export const inviteTransporterSchema = z.object({
  params: z.object({
    id: z.string().uuid()
  }),
  body: z.object({
    phone: z.string().min(8).max(20),
    expiresInHours: z.number().int().positive().max(720).optional(),
    permissions: z.record(z.boolean()).optional()
  })
});

import { LogAction } from '@prisma/client';
import { z } from 'zod';

const actionSchema = z.preprocess(
  (value) => (typeof value === 'string' ? value.toUpperCase() : value),
  z.nativeEnum(LogAction)
);

export const createLogSchema = z.object({
  body: z.object({
    shipmentId: z.string().uuid(),
    shipmentStepId: z.string().uuid().optional(),
    action: actionSchema,
    previousStatus: z.string().optional(),
    newStatus: z.string().optional(),
    notes: z.string().max(2000).optional(),
    confidenceScore: z.number().int().min(0).max(100).default(60)
  })
});

export const logShipmentParams = z.object({
  params: z.object({
    shipmentId: z.string().uuid()
  })
});

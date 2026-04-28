import { z } from 'zod';

export const createContactSchema = z.object({
  body: z.object({
    shipmentId: z.string().uuid(),
    userId: z.string().uuid(),
    priority: z.number().int().min(1).max(10),
    trustScore: z.number().min(0).max(100).default(50),
    escalationOrder: z.number().int().min(1),
    responseTimeAvg: z.number().int().min(0).default(0)
  })
});

export const contactShipmentParams = z.object({
  params: z.object({
    shipmentId: z.string().uuid()
  })
});

import { z } from 'zod';

export const triggerEscalationSchema = z.object({
  body: z.object({
    shipmentId: z.string().uuid(),
    stepId: z.string().uuid(),
    reason: z.string().max(1000).optional()
  })
});

export const escalationShipmentParams = z.object({
  params: z.object({
    shipmentId: z.string().uuid()
  })
});

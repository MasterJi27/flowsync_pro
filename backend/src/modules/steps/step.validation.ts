import { StepStatus } from '@prisma/client';
import { z } from 'zod';

const stepStatusSchema = z.preprocess(
  (value) => (typeof value === 'string' ? value.toUpperCase() : value),
  z.nativeEnum(StepStatus)
);

export const createStepSchema = z.object({
  params: z.object({
    id: z.string().uuid()
  }),
  body: z.object({
    stepName: z.string().min(2),
    sequenceOrder: z.number().int().positive(),
    expectedTime: z.coerce.date()
  })
});

export const updateStepSchema = z.object({
  params: z.object({
    id: z.string().uuid()
  }),
  body: z.object({
    stepName: z.string().min(2).optional(),
    sequenceOrder: z.number().int().positive().optional(),
    expectedTime: z.coerce.date().optional(),
    actualTime: z.coerce.date().optional(),
    status: stepStatusSchema.optional(),
    notes: z.string().max(2000).optional(),
    confidenceScore: z.number().int().min(0).max(100).optional()
  })
});

export const shipmentStepsParams = z.object({
  params: z.object({
    id: z.string().uuid()
  })
});

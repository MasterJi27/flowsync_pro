import { PriorityLevel, ShipmentStatus, TransportType } from '@prisma/client';
import { z } from 'zod';

const enumByName = <T extends Record<string, string>>(enumType: T) =>
  z.preprocess(
    (value) => (typeof value === 'string' ? value.toUpperCase() : value),
    z.nativeEnum(enumType)
  );

export const createShipmentSchema = z.object({
  body: z.object({
    referenceNumber: z.string().min(3).optional(),
    origin: z.string().min(2),
    destination: z.string().min(2),
    transportType: enumByName(TransportType),
    priorityLevel: enumByName(PriorityLevel).default(PriorityLevel.MEDIUM),
    steps: z
      .array(
        z.object({
          stepName: z.string().min(2),
          sequenceOrder: z.number().int().positive(),
          expectedTime: z.coerce.date()
        })
      )
      .optional()
  })
});

export const listShipmentsSchema = z.object({
  query: z.object({
    page: z.string().optional(),
    limit: z.string().optional(),
    search: z.string().optional(),
    status: enumByName(ShipmentStatus).optional(),
    priority: enumByName(PriorityLevel).optional(),
    sortBy: z
      .enum(['createdAt', 'updatedAt', 'priorityLevel', 'currentStatus', 'referenceNumber'])
      .default('updatedAt')
      .optional(),
    order: z.enum(['asc', 'desc']).default('desc').optional()
  })
});

export const shipmentIdSchema = z.object({
  params: z.object({
    id: z.string().uuid()
  })
});

export const updateShipmentSchema = z.object({
  params: z.object({
    id: z.string().uuid()
  }),
  body: z.object({
    origin: z.string().min(2).optional(),
    destination: z.string().min(2).optional(),
    transportType: enumByName(TransportType).optional(),
    currentStatus: enumByName(ShipmentStatus).optional(),
    currentStepId: z.string().uuid().nullable().optional(),
    priorityLevel: enumByName(PriorityLevel).optional()
  })
});

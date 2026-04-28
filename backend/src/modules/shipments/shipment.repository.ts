import { Prisma, ShipmentStatus } from '@prisma/client';
import { prisma } from '../../config/prisma';

export class ShipmentRepository {
  create(data: Prisma.ShipmentCreateInput) {
    return prisma.shipment.create({ data });
  }

  findById(id: string) {
    return prisma.shipment.findUnique({
      where: { id },
      include: {
        currentStep: true,
        steps: {
          orderBy: { sequenceOrder: 'asc' }
        },
        participants: {
          include: { user: true },
          orderBy: { createdAt: 'asc' }
        },
        contacts: {
          include: { user: true },
          orderBy: [{ priority: 'asc' }, { escalationOrder: 'asc' }]
        }
      }
    });
  }

  findMany(where: Prisma.ShipmentWhereInput, skip: number, take: number, orderBy: Prisma.ShipmentOrderByWithRelationInput) {
    return prisma.$transaction([
      prisma.shipment.findMany({
        where,
        skip,
        take,
        orderBy,
        include: {
          currentStep: true,
          steps: {
            orderBy: { sequenceOrder: 'asc' },
            take: 1
          },
          participants: {
            include: { user: true }
          },
          _count: {
            select: { steps: true, logs: true, escalationAttempts: true }
          }
        }
      }),
      prisma.shipment.count({ where })
    ]);
  }

  update(id: string, data: Prisma.ShipmentUpdateInput) {
    return prisma.shipment.update({
      where: { id },
      data,
      include: {
        currentStep: true,
        steps: { orderBy: { sequenceOrder: 'asc' } },
        participants: { include: { user: true } }
      }
    });
  }

  cancel(id: string) {
    return prisma.shipment.update({
      where: { id },
      data: {
        currentStatus: ShipmentStatus.CANCELLED
      }
    });
  }
}

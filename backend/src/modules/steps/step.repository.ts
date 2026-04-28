import { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';

export class StepRepository {
  create(data: Prisma.ShipmentStepCreateInput) {
    return prisma.shipmentStep.create({
      data,
      include: { shipment: true }
    });
  }

  findById(id: string) {
    return prisma.shipmentStep.findUnique({
      where: { id },
      include: {
        shipment: true,
        updatedByUser: true
      }
    });
  }

  list(shipmentId: string) {
    return prisma.shipmentStep.findMany({
      where: { shipmentId },
      include: { updatedByUser: true },
      orderBy: { sequenceOrder: 'asc' }
    });
  }
}

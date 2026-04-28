import { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';

export class LogRepository {
  create(data: Prisma.ShipmentLogCreateInput) {
    return prisma.shipmentLog.create({ data });
  }

  list(shipmentId: string) {
    return prisma.shipmentLog.findMany({
      where: { shipmentId },
      include: {
        performer: true,
        shipmentStep: true
      },
      orderBy: { timestamp: 'desc' }
    });
  }
}

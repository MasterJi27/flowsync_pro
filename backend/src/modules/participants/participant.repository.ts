import { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';

export class ParticipantRepository {
  list(shipmentId: string) {
    return prisma.shipmentParticipant.findMany({
      where: { shipmentId },
      include: { user: true },
      orderBy: [{ participantRole: 'asc' }, { createdAt: 'asc' }]
    });
  }

  create(data: Prisma.ShipmentParticipantCreateInput) {
    return prisma.shipmentParticipant.create({
      data,
      include: { user: true, shipment: true }
    });
  }

  findById(id: string) {
    return prisma.shipmentParticipant.findUnique({
      where: { id },
      include: { user: true, shipment: true }
    });
  }
}

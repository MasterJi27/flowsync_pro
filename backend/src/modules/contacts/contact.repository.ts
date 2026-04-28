import { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';

export class ContactRepository {
  create(data: Prisma.ContactCreateInput) {
    return prisma.contact.create({
      data,
      include: { user: true, shipment: true }
    });
  }

  list(shipmentId: string) {
    return prisma.contact.findMany({
      where: { shipmentId },
      include: { user: true },
      orderBy: [{ priority: 'asc' }, { trustScore: 'desc' }, { escalationOrder: 'asc' }]
    });
  }
}

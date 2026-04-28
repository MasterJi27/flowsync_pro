import { SourceType } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { assertCan, actorRole, getShipmentAccess } from '../../shared/permissions';
import { notFound } from '../../shared/errors';
import { AuthContext } from '../../types/express';
import { ContactRepository } from './contact.repository';

type CreateContactInput = {
  shipmentId: string;
  userId: string;
  priority: number;
  trustScore: number;
  escalationOrder: number;
  responseTimeAvg: number;
};

export class ContactService {
  constructor(private readonly repo = new ContactRepository()) {}

  async create(auth: AuthContext | undefined, input: CreateContactInput) {
    const access = await getShipmentAccess(auth, input.shipmentId);
    assertCan(access, 'participants.manage');

    const user = await prisma.user.findUnique({ where: { id: input.userId } });
    if (!user) {
      throw notFound('User');
    }

    const contact = await this.repo.create({
      shipment: { connect: { id: input.shipmentId } },
      user: { connect: { id: input.userId } },
      priority: input.priority,
      trustScore: input.trustScore,
      escalationOrder: input.escalationOrder,
      responseTimeAvg: input.responseTimeAvg
    });

    await prisma.shipmentLog.create({
      data: {
        shipmentId: input.shipmentId,
        performedBy: auth?.userId,
        performerRole: actorRole(access),
        action: 'PARTICIPANT_ADDED',
        notes: `${user.name} added to escalation contact sequence`,
        sourceType: SourceType.USER,
        confidenceScore: 80
      }
    });

    return contact;
  }

  async list(auth: AuthContext | undefined, shipmentId: string) {
    await getShipmentAccess(auth, shipmentId);
    return this.repo.list(shipmentId);
  }
}

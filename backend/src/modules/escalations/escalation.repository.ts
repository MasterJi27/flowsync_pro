import { Prisma } from '@prisma/client';
import { prisma } from '../../config/prisma';

export class EscalationRepository {
  list(shipmentId: string) {
    return prisma.escalationAttempt.findMany({
      where: { shipmentId },
      include: {
        contact: { include: { user: true } },
        participant: { include: { user: true } },
        shipmentStep: true
      },
      orderBy: [{ createdAt: 'desc' }, { sequenceRank: 'asc' }]
    });
  }

  createMany(data: Prisma.EscalationAttemptCreateManyInput[]) {
    return prisma.escalationAttempt.createMany({ data });
  }

  unresolvedForStep(stepId: string) {
    return prisma.escalationAttempt.findMany({
      where: {
        shipmentStepId: stepId,
        status: { in: ['PENDING', 'NOTIFIED'] }
      }
    });
  }
}

import { EscalationAttemptStatus, LogAction, SourceType, StepStatus } from '@prisma/client';
import dayjs from 'dayjs';
import { prisma } from '../../config/prisma';
import { env } from '../../config/env';
import { socketEvents } from '../../realtime/events';
import { emitParticipant, emitShipment, emitUser } from '../../realtime/socket';
import { AppError, notFound } from '../../shared/errors';
import { assertCan, actorRole, getShipmentAccess } from '../../shared/permissions';
import { penalizeMissedParticipant } from '../../shared/reliability';
import { AuthContext } from '../../types/express';
import { EscalationRepository } from './escalation.repository';

type TriggerInput = {
  shipmentId: string;
  stepId: string;
  reason?: string;
};

export class EscalationService {
  constructor(private readonly repo = new EscalationRepository()) {}

  async trigger(auth: AuthContext | undefined, input: TriggerInput) {
    const access = await getShipmentAccess(auth, input.shipmentId);
    assertCan(access, 'escalation.trigger');
    return this.triggerInternal(input, {
      performedBy: auth?.userId,
      performerRole: actorRole(access),
      sourceType: auth?.sessionType === 'INVITE' ? SourceType.INVITE : SourceType.USER
    });
  }

  async triggerSystem(input: TriggerInput) {
    return this.triggerInternal(input, {
      sourceType: SourceType.SYSTEM,
      performerRole: undefined,
      performedBy: undefined
    });
  }

  async list(auth: AuthContext | undefined, shipmentId: string) {
    await getShipmentAccess(auth, shipmentId);
    return this.repo.list(shipmentId);
  }

  async advanceStaleEscalations() {
    const stale = await prisma.escalationAttempt.findMany({
      where: {
        status: EscalationAttemptStatus.NOTIFIED,
        notifiedAt: {
          lt: dayjs().subtract(env.ESCALATION_STEP_MINUTES, 'minute').toDate()
        }
      },
      include: {
        shipmentStep: true,
        participant: true,
        contact: true
      }
    });

    for (const attempt of stale) {
      const responded = await prisma.escalationAttempt.findFirst({
        where: {
          shipmentStepId: attempt.shipmentStepId,
          status: EscalationAttemptStatus.RESPONDED
        }
      });
      if (responded) continue;

      await prisma.escalationAttempt.update({
        where: { id: attempt.id },
        data: {
          status: EscalationAttemptStatus.EXPIRED,
          notes: 'No response before escalation window elapsed'
        }
      });
      await penalizeMissedParticipant(attempt.participantId ?? undefined);

      const next = await prisma.escalationAttempt.findFirst({
        where: {
          shipmentStepId: attempt.shipmentStepId,
          status: EscalationAttemptStatus.PENDING
        },
        orderBy: { sequenceRank: 'asc' }
      });

      if (next) {
        const notified = await prisma.escalationAttempt.update({
          where: { id: next.id },
          data: {
            status: EscalationAttemptStatus.NOTIFIED,
            notifiedAt: new Date(),
            notes: 'Escalation advanced after previous contact missed response window'
          },
          include: {
            contact: { include: { user: true } },
            participant: { include: { user: true } }
          }
        });

        await prisma.shipmentLog.create({
          data: {
            shipmentId: attempt.shipmentId,
            shipmentStepId: attempt.shipmentStepId,
            action: LogAction.ESCALATION_ADVANCED,
            previousStatus: EscalationAttemptStatus.EXPIRED,
            newStatus: EscalationAttemptStatus.NOTIFIED,
            notes: `Escalation advanced to sequence ${notified.sequenceRank}`,
            sourceType: SourceType.SYSTEM,
            confidenceScore: 75
          }
        });

        this.notifyAttempt(notified);
        emitShipment(attempt.shipmentId, socketEvents.escalationUpdated, {
          shipmentId: attempt.shipmentId,
          stepId: attempt.shipmentStepId,
          attempt: notified
        });
      }
    }
  }

  private async triggerInternal(
    input: TriggerInput,
    actor: {
      performedBy?: string;
      performerRole?: 'BROKER' | 'CLIENT' | 'TRANSPORTER' | 'AUTHORITY';
      sourceType: SourceType;
    }
  ) {
    const step = await prisma.shipmentStep.findFirst({
      where: { id: input.stepId, shipmentId: input.shipmentId },
      include: { shipment: true }
    });
    if (!step) {
      throw notFound('Shipment step');
    }
    if (step.status === StepStatus.COMPLETED) {
      throw new AppError(409, 'STEP_ALREADY_COMPLETED', 'Completed steps cannot be escalated');
    }

    const existing = await this.repo.unresolvedForStep(step.id);
    if (existing.length > 0) {
      return this.repo.list(input.shipmentId);
    }

    const rankedTargets = await this.rankedEscalationTargets(input.shipmentId);
    const now = new Date();

    await prisma.$transaction(async (tx) => {
      await tx.shipmentStep.update({
        where: { id: step.id },
        data: {
          status: StepStatus.NEEDS_CONFIRMATION,
          escalationStatus: 'IN_PROGRESS',
          updateSource: 'SYSTEM'
        }
      });

      await tx.shipment.update({
        where: { id: input.shipmentId },
        data: {
          currentStatus: 'NEEDS_CONFIRMATION',
          currentStepId: step.id
        }
      });

      if (rankedTargets.length > 0) {
        await tx.escalationAttempt.createMany({
          data: rankedTargets.map((target, index) => ({
            shipmentId: input.shipmentId,
            shipmentStepId: step.id,
            contactId: target.contactId,
            participantId: target.participantId,
            sequenceRank: index + 1,
            status:
              index === 0
                ? EscalationAttemptStatus.NOTIFIED
                : EscalationAttemptStatus.PENDING,
            notifiedAt: index === 0 ? now : undefined,
            notes: index === 0 ? input.reason ?? 'Step needs first confirmation' : undefined
          }))
        });
      }

      await tx.shipmentLog.create({
        data: {
          shipmentId: input.shipmentId,
          shipmentStepId: step.id,
          performedBy: actor.performedBy,
          performerRole: actor.performerRole,
          action: LogAction.ESCALATION_TRIGGERED,
          previousStatus: step.status,
          newStatus: StepStatus.NEEDS_CONFIRMATION,
          notes: input.reason ?? 'Expected update missing; escalation sequence triggered',
          sourceType: actor.sourceType,
          confidenceScore: 75
        }
      });
    });

    const attempts = await this.repo.list(input.shipmentId);
    const first = attempts.find(
      (attempt) =>
        attempt.shipmentStepId === step.id && attempt.status === EscalationAttemptStatus.NOTIFIED
    );
    if (first) this.notifyAttempt(first);

    emitShipment(input.shipmentId, socketEvents.escalationUpdated, {
      shipmentId: input.shipmentId,
      stepId: step.id,
      attempts
    });
    emitShipment(input.shipmentId, socketEvents.stepUpdated, {
      shipmentId: input.shipmentId,
      stepId: step.id,
      status: StepStatus.NEEDS_CONFIRMATION
    });

    return attempts;
  }

  private async rankedEscalationTargets(shipmentId: string) {
    const [contacts, brokerParticipants] = await Promise.all([
      prisma.contact.findMany({
        where: { shipmentId },
        include: { user: true },
        orderBy: [{ priority: 'asc' }, { escalationOrder: 'asc' }]
      }),
      prisma.shipmentParticipant.findMany({
        where: { shipmentId, participantRole: 'BROKER' },
        include: { user: true }
      })
    ]);

    const userIds = contacts.map((contact) => contact.userId);
    const participantByUser = await prisma.shipmentParticipant.findMany({
      where: {
        shipmentId,
        userId: { in: userIds }
      }
    });

    const participantMap = new Map(participantByUser.map((participant) => [participant.userId, participant]));

    const rankedContacts = contacts
      .map((contact) => ({
        contactId: contact.id,
        participantId: participantMap.get(contact.userId)?.id,
        userId: contact.userId,
        priority: contact.priority,
        trustScore: Number(contact.trustScore),
        responseRate: Number(participantMap.get(contact.userId)?.responseRate ?? 0),
        responseTimeAvg: contact.responseTimeAvg,
        escalationOrder: contact.escalationOrder
      }))
      .sort(
        (a, b) =>
          a.priority - b.priority ||
          b.trustScore - a.trustScore ||
          b.responseRate - a.responseRate ||
          a.responseTimeAvg - b.responseTimeAvg ||
          a.escalationOrder - b.escalationOrder
      );

    if (rankedContacts.length > 0) {
      return rankedContacts;
    }

    return brokerParticipants.map((participant, index) => ({
      participantId: participant.id,
      contactId: undefined,
      userId: participant.userId,
      priority: 1,
      trustScore: Number(participant.reliabilityScore),
      responseRate: Number(participant.responseRate),
      responseTimeAvg: 0,
      escalationOrder: index + 1
    }));
  }

  private notifyAttempt(attempt: {
    id: string;
    shipmentId: string;
    shipmentStepId: string;
    sequenceRank: number;
    participantId?: string | null;
    contact?: { userId: string } | null;
    participant?: { userId?: string | null } | null;
  }) {
    const payload = {
      type: 'ESCALATION_REQUEST',
      attemptId: attempt.id,
      shipmentId: attempt.shipmentId,
      stepId: attempt.shipmentStepId,
      sequenceRank: attempt.sequenceRank
    };

    if (attempt.contact?.userId) {
      emitUser(attempt.contact.userId, socketEvents.notification, payload);
    }
    if (attempt.participant?.userId) {
      emitUser(attempt.participant.userId, socketEvents.notification, payload);
    }
    if (attempt.participantId) {
      emitParticipant(attempt.participantId, socketEvents.notification, payload);
    }
  }
}

import {
  EscalationAttemptStatus,
  EscalationStatus,
  LogAction,
  ShipmentStatus,
  SourceType,
  StepStatus
} from '@prisma/client';
import { prisma } from '../../config/prisma';
import { socketEvents } from '../../realtime/events';
import { emitShipment } from '../../realtime/socket';
import { AppError, forbidden, notFound } from '../../shared/errors';
import { actorRole, assertCan, getShipmentAccess } from '../../shared/permissions';
import {
  confidenceForUpdate,
  sourceForRole,
  updateParticipantReliability
} from '../../shared/reliability';
import { AuthContext } from '../../types/express';
import { StepRepository } from './step.repository';

type CreateStepInput = {
  stepName: string;
  sequenceOrder: number;
  expectedTime: Date;
};

type UpdateStepInput = {
  stepName?: string;
  sequenceOrder?: number;
  expectedTime?: Date;
  actualTime?: Date;
  status?: StepStatus;
  notes?: string;
  confidenceScore?: number;
};

export class StepService {
  constructor(private readonly repo = new StepRepository()) {}

  async create(auth: AuthContext | undefined, shipmentId: string, input: CreateStepInput) {
    const access = await getShipmentAccess(auth, shipmentId);
    assertCan(access, 'steps.create');

    const step = await this.repo.create({
      shipment: { connect: { id: shipmentId } },
      stepName: input.stepName,
      sequenceOrder: input.sequenceOrder,
      expectedTime: input.expectedTime,
      updateSource: 'BROKER',
      confidenceScore: 80,
      updatedByUser: auth?.userId ? { connect: { id: auth.userId } } : undefined
    });

    const shipment = await prisma.shipment.findUnique({ where: { id: shipmentId } });
    if (shipment && !shipment.currentStepId) {
      await prisma.shipment.update({
        where: { id: shipmentId },
        data: { currentStepId: step.id }
      });
    }

    await prisma.shipmentLog.create({
      data: {
        shipmentId,
        shipmentStepId: step.id,
        performedBy: auth?.userId,
        performerRole: actorRole(access),
        action: LogAction.STEP_CREATED,
        newStatus: StepStatus.PENDING,
        notes: `${input.stepName} step created`,
        sourceType: SourceType.USER,
        confidenceScore: 80
      }
    });

    emitShipment(shipmentId, socketEvents.stepUpdated, { shipmentId, step });
    return step;
  }

  async list(auth: AuthContext | undefined, shipmentId: string) {
    await getShipmentAccess(auth, shipmentId);
    return this.repo.list(shipmentId);
  }

  async update(auth: AuthContext | undefined, stepId: string, input: UpdateStepInput) {
    const existing = await this.repo.findById(stepId);
    if (!existing) {
      throw notFound('Shipment step');
    }

    const access = await getShipmentAccess(auth, existing.shipmentId);
    const role = actorRole(access);
    const structuralChange =
      input.stepName !== undefined ||
      input.sequenceOrder !== undefined ||
      input.expectedTime !== undefined;

    if (structuralChange) {
      assertCan(access, 'steps.override');
    } else {
      assertCan(access, 'steps.update');
    }

    if (role === 'CLIENT') {
      throw forbidden('Clients have read-only timeline access');
    }

    if (role === 'AUTHORITY' && input.status && !access.permissions['compliance.confirm']) {
      throw forbidden('Authority session cannot confirm compliance for this shipment');
    }

    const isValidConfirmation =
      input.status === StepStatus.IN_PROGRESS || input.status === StepStatus.COMPLETED;
    const needsFirstConfirmation =
      isValidConfirmation &&
      !existing.actualTime &&
      (existing.status === StepStatus.NEEDS_CONFIRMATION ||
        existing.status === StepStatus.ESCALATED ||
        existing.escalationStatus === EscalationStatus.IN_PROGRESS ||
        existing.escalationStatus === EscalationStatus.NEEDS_CONFIRMATION);

    const priorFirst = await prisma.shipmentLog.findFirst({
      where: {
        shipmentStepId: stepId,
        isFirstConfirmation: true
      }
    });

    const isFirstConfirmation = needsFirstConfirmation && !priorFirst;
    const participantReliability = Number(access.participant?.reliabilityScore ?? 90);
    const confidenceScore = confidenceForUpdate(role, participantReliability, input.confidenceScore);
    const updateSource = sourceForRole(role);

    const result = await prisma.$transaction(async (tx) => {
      const updated = await tx.shipmentStep.update({
        where: { id: stepId },
        data: {
          stepName: input.stepName,
          sequenceOrder: input.sequenceOrder,
          expectedTime: input.expectedTime,
          actualTime:
            input.actualTime ??
            (input.status === StepStatus.COMPLETED || input.status === StepStatus.IN_PROGRESS
              ? new Date()
              : undefined),
          status: input.status,
          updatedBy: auth?.userId,
          confidenceScore,
          updateSource,
          escalationStatus: isFirstConfirmation ? EscalationStatus.RESOLVED : undefined
        },
        include: {
          updatedByUser: true,
          shipment: true
        }
      });

      const allSteps = await tx.shipmentStep.findMany({
        where: { shipmentId: existing.shipmentId },
        orderBy: { sequenceOrder: 'asc' }
      });
      const firstOpen = allSteps.find((step) => step.status !== StepStatus.COMPLETED);
      const allCompleted = allSteps.length > 0 && allSteps.every((step) => step.status === StepStatus.COMPLETED);

      const shipmentStatus = this.deriveShipmentStatus(allSteps, updated.status);
      await tx.shipment.update({
        where: { id: existing.shipmentId },
        data: {
          currentStatus: allCompleted ? ShipmentStatus.COMPLETED : shipmentStatus,
          currentStepId: allCompleted ? null : firstOpen?.id ?? updated.id
        }
      });

      if (isFirstConfirmation) {
        const attempts = await tx.escalationAttempt.findMany({
          where: {
            shipmentStepId: stepId,
            status: { in: [EscalationAttemptStatus.PENDING, EscalationAttemptStatus.NOTIFIED] }
          },
          include: {
            contact: true
          }
        });

        for (const attempt of attempts) {
          const isResponder =
            attempt.participantId === access.participant?.id ||
            (auth?.userId !== undefined && attempt.contact?.userId === auth.userId);
          await tx.escalationAttempt.update({
            where: { id: attempt.id },
            data: {
              status: isResponder
                ? EscalationAttemptStatus.RESPONDED
                : EscalationAttemptStatus.SKIPPED,
              respondedAt: isResponder ? new Date() : undefined,
              notes: isResponder
                ? 'First valid confirmation received from this responder'
                : 'Skipped because first confirmation was received elsewhere'
            }
          });
        }
      }

      await tx.shipmentLog.create({
        data: {
          shipmentId: existing.shipmentId,
          shipmentStepId: stepId,
          performedBy: auth?.userId,
          performerRole: role,
          action: isFirstConfirmation ? LogAction.FIRST_CONFIRMATION : LogAction.STEP_UPDATED,
          previousStatus: existing.status,
          newStatus: updated.status,
          notes: input.notes,
          isFirstConfirmation,
          sourceType: auth?.sessionType === 'INVITE' ? SourceType.INVITE : SourceType.USER,
          confidenceScore
        }
      });

      if (auth?.userId) {
        const contact = await tx.contact.findUnique({
          where: {
            shipmentId_userId: {
              shipmentId: existing.shipmentId,
              userId: auth.userId
            }
          }
        });
        if (contact) {
          const responseMinutes = Math.max(
            0,
            Math.round(((updated.actualTime ?? new Date()).getTime() - existing.expectedTime.getTime()) / 60000)
          );
          await tx.contact.update({
            where: { id: contact.id },
            data: {
              responseTimeAvg:
                contact.responseTimeAvg === 0
                  ? responseMinutes
                  : Math.round((contact.responseTimeAvg + responseMinutes) / 2)
            }
          });
        }
      }

      return updated;
    });

    await updateParticipantReliability({
      participantId: access.participant?.id,
      stepId,
      status: result.status,
      isFirstConfirmation
    });

    emitShipment(existing.shipmentId, socketEvents.stepUpdated, {
      shipmentId: existing.shipmentId,
      step: result,
      isFirstConfirmation
    });
    emitShipment(existing.shipmentId, socketEvents.shipmentUpdated, {
      shipmentId: existing.shipmentId
    });

    return result;
  }

  private deriveShipmentStatus(steps: Array<{ status: StepStatus }>, updatedStatus: StepStatus) {
    if (updatedStatus === StepStatus.BLOCKED) return ShipmentStatus.DELAYED;
    if (updatedStatus === StepStatus.ESCALATED) return ShipmentStatus.ESCALATED;
    if (updatedStatus === StepStatus.NEEDS_CONFIRMATION) return ShipmentStatus.NEEDS_CONFIRMATION;
    if (steps.some((step) => step.status === StepStatus.NEEDS_CONFIRMATION)) {
      return ShipmentStatus.NEEDS_CONFIRMATION;
    }
    if (steps.some((step) => step.status === StepStatus.ESCALATED || step.status === StepStatus.BLOCKED)) {
      return ShipmentStatus.ESCALATED;
    }
    if (steps.some((step) => step.status === StepStatus.IN_PROGRESS || step.status === StepStatus.COMPLETED)) {
      return ShipmentStatus.IN_TRANSIT;
    }
    return ShipmentStatus.PLANNED;
  }
}

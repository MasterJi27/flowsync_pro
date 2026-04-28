import { SourceType } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { socketEvents } from '../../realtime/events';
import { emitShipment } from '../../realtime/socket';
import { AppError, notFound } from '../../shared/errors';
import { actorRole, getShipmentAccess } from '../../shared/permissions';
import { AuthContext } from '../../types/express';
import { LogRepository } from './log.repository';

type CreateLogInput = {
  shipmentId: string;
  shipmentStepId?: string;
  action: string;
  previousStatus?: string;
  newStatus?: string;
  notes?: string;
  confidenceScore: number;
};

export class LogService {
  constructor(private readonly repo = new LogRepository()) {}

  async create(auth: AuthContext | undefined, input: CreateLogInput) {
    const access = await getShipmentAccess(auth, input.shipmentId);

    if (input.shipmentStepId) {
      const step = await prisma.shipmentStep.findFirst({
        where: { id: input.shipmentStepId, shipmentId: input.shipmentId }
      });
      if (!step) {
        throw new AppError(422, 'INVALID_STEP', 'Shipment step does not belong to this shipment');
      }
    }

    const log = await this.repo.create({
      shipment: { connect: { id: input.shipmentId } },
      shipmentStep: input.shipmentStepId ? { connect: { id: input.shipmentStepId } } : undefined,
      performer: auth?.userId ? { connect: { id: auth.userId } } : undefined,
      performerRole: actorRole(access),
      action: input.action as never,
      previousStatus: input.previousStatus,
      newStatus: input.newStatus,
      notes: input.notes,
      sourceType: auth?.sessionType === 'INVITE' ? SourceType.INVITE : SourceType.USER,
      confidenceScore: input.confidenceScore
    });

    emitShipment(input.shipmentId, socketEvents.shipmentUpdated, {
      shipmentId: input.shipmentId,
      log
    });
    return log;
  }

  async list(auth: AuthContext | undefined, shipmentId: string) {
    await getShipmentAccess(auth, shipmentId);
    const shipment = await prisma.shipment.findUnique({ where: { id: shipmentId } });
    if (!shipment) {
      throw notFound('Shipment');
    }
    return this.repo.list(shipmentId);
  }
}

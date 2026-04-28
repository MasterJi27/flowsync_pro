import { LogAction, Prisma, ShipmentStatus, SourceType } from '@prisma/client';
import crypto from 'crypto';
import { prisma } from '../../config/prisma';
import { permissionTemplates } from '../../constants/permissions';
import { socketEvents } from '../../realtime/events';
import { emitShipment } from '../../realtime/socket';
import { AppError, forbidden, notFound, unauthorized } from '../../shared/errors';
import { getShipmentAccess, assertCan, actorRole } from '../../shared/permissions';
import { paginationParams, paginated } from '../../shared/pagination';
import { AuthContext } from '../../types/express';
import { ShipmentRepository } from './shipment.repository';

type CreateShipmentInput = {
  referenceNumber?: string;
  origin: string;
  destination: string;
  transportType: 'ROAD' | 'AIR' | 'SEA' | 'RAIL' | 'MULTIMODAL';
  priorityLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  steps?: Array<{
    stepName: string;
    sequenceOrder: number;
    expectedTime: Date;
  }>;
};

type ListQuery = {
  page?: string;
  limit?: string;
  search?: string;
  status?: ShipmentStatus;
  priority?: string;
  sortBy?: 'createdAt' | 'updatedAt' | 'priorityLevel' | 'currentStatus' | 'referenceNumber';
  order?: 'asc' | 'desc';
};

type UpdateShipmentInput = {
  origin?: string;
  destination?: string;
  transportType?: 'ROAD' | 'AIR' | 'SEA' | 'RAIL' | 'MULTIMODAL';
  currentStatus?: ShipmentStatus;
  currentStepId?: string | null;
  priorityLevel?: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
};

export class ShipmentService {
  constructor(private readonly repo = new ShipmentRepository()) {}

  async create(auth: AuthContext | undefined, input: CreateShipmentInput) {
    if (!auth?.userId) {
      throw unauthorized('Only full user accounts can create shipments');
    }
    if (!['BROKER', 'ADMIN'].includes(auth.globalRole ?? '')) {
      throw forbidden('Only brokers can create shipments');
    }

    const referenceNumber =
      input.referenceNumber ?? `FS-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;

    const shipment = await prisma.$transaction(async (tx) => {
      const created = await tx.shipment.create({
        data: {
          referenceNumber,
          origin: input.origin,
          destination: input.destination,
          transportType: input.transportType,
          priorityLevel: input.priorityLevel,
          createdBy: auth.userId!,
          participants: {
            create: {
              userId: auth.userId!,
              participantRole: 'BROKER',
              permissions: permissionTemplates.BROKER,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 95,
              responseRate: 100,
              lastActivityAt: new Date()
            }
          },
          steps: {
            create:
              input.steps?.map((step) => ({
                stepName: step.stepName,
                sequenceOrder: step.sequenceOrder,
                expectedTime: step.expectedTime,
                updateSource: 'SYSTEM',
                confidenceScore: 60
              })) ?? []
          }
        },
        include: {
          steps: {
            orderBy: { sequenceOrder: 'asc' }
          },
          participants: true
        }
      });

      const firstStep = created.steps[0];
      const withCurrent = firstStep
        ? await tx.shipment.update({
            where: { id: created.id },
            data: { currentStepId: firstStep.id },
            include: {
              currentStep: true,
              steps: { orderBy: { sequenceOrder: 'asc' } },
              participants: true
            }
          })
        : created;

      await tx.shipmentLog.create({
        data: {
          shipmentId: created.id,
          performedBy: auth.userId!,
          performerRole: 'BROKER',
          action: LogAction.SHIPMENT_CREATED,
          newStatus: ShipmentStatus.PLANNED,
          notes: `Shipment ${referenceNumber} created`,
          sourceType: SourceType.USER,
          confidenceScore: 90
        }
      });

      return withCurrent;
    });

    emitShipment(shipment.id, socketEvents.shipmentUpdated, { shipmentId: shipment.id, shipment });
    return shipment;
  }

  async list(auth: AuthContext | undefined, query: ListQuery) {
    if (!auth) {
      throw unauthorized();
    }
    const { page, limit, skip } = paginationParams(query);

    const filters: Prisma.ShipmentWhereInput[] = [];
    if (query.search) {
      filters.push({
        OR: [
          { referenceNumber: { contains: query.search, mode: 'insensitive' } },
          { origin: { contains: query.search, mode: 'insensitive' } },
          { destination: { contains: query.search, mode: 'insensitive' } }
        ]
      });
    }
    if (query.status) {
      filters.push({ currentStatus: query.status });
    }
    if (query.priority) {
      filters.push({ priorityLevel: query.priority as never });
    }

    const accessFilter: Prisma.ShipmentWhereInput =
      auth.sessionType === 'INVITE'
        ? { id: auth.shipmentId }
        : auth.globalRole === 'ADMIN'
          ? {}
          : {
              participants: {
                some: { userId: auth.userId }
              }
            };

    const where: Prisma.ShipmentWhereInput = {
      AND: [accessFilter, ...filters]
    };

    const [items, total] = await this.repo.findMany(where, skip, limit, {
      [query.sortBy ?? 'updatedAt']: query.order ?? 'desc'
    });

    return paginated(items, total, page, limit);
  }

  async get(auth: AuthContext | undefined, id: string) {
    await getShipmentAccess(auth, id);
    const shipment = await this.repo.findById(id);
    if (!shipment) {
      throw notFound('Shipment');
    }
    return shipment;
  }

  async update(auth: AuthContext | undefined, id: string, input: UpdateShipmentInput) {
    const access = await getShipmentAccess(auth, id);
    assertCan(access, 'shipment.write');

    const before = await this.repo.findById(id);
    if (!before) {
      throw notFound('Shipment');
    }

    if (input.currentStepId) {
      const step = await prisma.shipmentStep.findFirst({
        where: { id: input.currentStepId, shipmentId: id }
      });
      if (!step) {
        throw new AppError(422, 'INVALID_STEP', 'Current step must belong to this shipment');
      }
    }

    const updateData: Prisma.ShipmentUpdateInput = {
      origin: input.origin,
      destination: input.destination,
      transportType: input.transportType,
      currentStatus: input.currentStatus,
      priorityLevel: input.priorityLevel,
      currentStep:
        input.currentStepId === undefined
          ? undefined
          : input.currentStepId === null
            ? { disconnect: true }
            : { connect: { id: input.currentStepId } }
    };

    const updated = await this.repo.update(id, updateData);
    await prisma.shipmentLog.create({
      data: {
        shipmentId: id,
        performedBy: auth?.userId,
        performerRole: actorRole(access),
        action: LogAction.SHIPMENT_UPDATED,
        previousStatus: before.currentStatus,
        newStatus: updated.currentStatus,
        notes: 'Shipment metadata updated',
        sourceType: auth?.sessionType === 'INVITE' ? SourceType.INVITE : SourceType.USER,
        confidenceScore: 85
      }
    });

    emitShipment(id, socketEvents.shipmentUpdated, { shipmentId: id, shipment: updated });
    return updated;
  }

  async cancel(auth: AuthContext | undefined, id: string) {
    const access = await getShipmentAccess(auth, id);
    assertCan(access, 'shipment.delete');

    const before = await this.repo.findById(id);
    if (!before) {
      throw notFound('Shipment');
    }

    const cancelled = await this.repo.cancel(id);
    await prisma.shipmentLog.create({
      data: {
        shipmentId: id,
        performedBy: auth?.userId,
        performerRole: actorRole(access),
        action: LogAction.SHIPMENT_DELETED,
        previousStatus: before.currentStatus,
        newStatus: ShipmentStatus.CANCELLED,
        notes: 'Shipment cancelled through DELETE endpoint; audit records preserved',
        sourceType: SourceType.USER,
        confidenceScore: 90
      }
    });

    emitShipment(id, socketEvents.shipmentUpdated, { shipmentId: id, shipment: cancelled });
    return cancelled;
  }
}

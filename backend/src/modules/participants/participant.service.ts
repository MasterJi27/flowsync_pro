import crypto from 'crypto';
import { ParticipantRole, SourceType } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { env } from '../../config/env';
import { permissionTemplates } from '../../constants/permissions';
import { socketEvents } from '../../realtime/events';
import { emitShipment } from '../../realtime/socket';
import { notFound } from '../../shared/errors';
import { assertCan, actorRole, getShipmentAccess } from '../../shared/permissions';
import { AuthContext } from '../../types/express';
import { ParticipantRepository } from './participant.repository';

type AddParticipantInput = {
  userId: string;
  participantRole: ParticipantRole;
  permissions?: Record<string, boolean>;
};

type InviteTransporterInput = {
  phone: string;
  expiresInHours?: number;
  permissions?: Record<string, boolean>;
};

export class ParticipantService {
  constructor(private readonly repo = new ParticipantRepository()) {}

  async list(auth: AuthContext | undefined, shipmentId: string) {
    await getShipmentAccess(auth, shipmentId);
    return this.repo.list(shipmentId);
  }

  async add(auth: AuthContext | undefined, shipmentId: string, input: AddParticipantInput) {
    const access = await getShipmentAccess(auth, shipmentId);
    assertCan(access, 'participants.manage');

    const user = await prisma.user.findUnique({ where: { id: input.userId } });
    if (!user) {
      throw notFound('User');
    }

    const participant = await this.repo.create({
      shipment: { connect: { id: shipmentId } },
      user: { connect: { id: input.userId } },
      participantRole: input.participantRole,
      permissions: input.permissions ?? permissionTemplates[input.participantRole],
      inviteStatus: 'JOINED',
      joinedAt: new Date(),
      reliabilityScore: input.participantRole === 'CLIENT' ? 80 : 60,
      responseRate: input.participantRole === 'CLIENT' ? 100 : 0,
      lastActivityAt: new Date()
    });

    await prisma.shipmentLog.create({
      data: {
        shipmentId,
        performedBy: auth?.userId,
        performerRole: actorRole(access),
        action: 'PARTICIPANT_ADDED',
        notes: `${user.name} added as ${input.participantRole}`,
        sourceType: SourceType.USER,
        confidenceScore: 90
      }
    });

    emitShipment(shipmentId, socketEvents.participantUpdated, { shipmentId, participant });
    return participant;
  }

  async inviteTransporter(
    auth: AuthContext | undefined,
    shipmentId: string,
    input: InviteTransporterInput
  ) {
    const access = await getShipmentAccess(auth, shipmentId);
    assertCan(access, 'participants.manage');

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(
      Date.now() + (input.expiresInHours ?? env.INVITE_EXPIRES_HOURS) * 60 * 60 * 1000
    );

    const participant = await this.repo.create({
      shipment: { connect: { id: shipmentId } },
      participantRole: 'TRANSPORTER',
      permissions: input.permissions ?? permissionTemplates.TRANSPORTER,
      inviteToken: token,
      invitePhone: input.phone,
      inviteStatus: 'PENDING',
      inviteExpiresAt: expiresAt,
      reliabilityScore: 50,
      responseRate: 0
    });

    await prisma.shipmentLog.create({
      data: {
        shipmentId,
        performedBy: auth?.userId,
        performerRole: actorRole(access),
        action: 'PARTICIPANT_INVITED',
        notes: `Transporter invite created for ${input.phone}`,
        sourceType: SourceType.USER,
        confidenceScore: 85
      }
    });

    const payload = {
      participant,
      invite: {
        token,
        expiresAt,
        phone: input.phone,
        deepLink: `flowsyncpro://invite?token=${token}`,
        apiAccess: `/auth/invite-access`
      }
    };

    emitShipment(shipmentId, socketEvents.participantUpdated, { shipmentId, participant });
    return payload;
  }
}

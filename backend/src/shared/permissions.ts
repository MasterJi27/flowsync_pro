import { Prisma, ShipmentParticipant } from '@prisma/client';
import { prisma } from '../config/prisma';
import { permissionTemplates } from '../constants/permissions';
import { forbidden, unauthorized } from './errors';
import { AuthContext } from '../types/express';

export type ShipmentAccess = {
  participant?: ShipmentParticipant;
  permissions: Record<string, boolean>;
  isAdmin: boolean;
};

const asPermissions = (value: Prisma.JsonValue | undefined, fallback: Record<string, boolean>) => {
  if (!value || Array.isArray(value) || typeof value !== 'object') {
    return fallback;
  }
  return { ...fallback, ...(value as Record<string, boolean>) };
};

export const getShipmentAccess = async (
  auth: AuthContext | undefined,
  shipmentId: string
): Promise<ShipmentAccess> => {
  if (!auth) {
    throw unauthorized();
  }

  if (auth.sessionType === 'USER' && auth.globalRole === 'ADMIN') {
    return { permissions: permissionTemplates.BROKER, isAdmin: true };
  }

  if (auth.sessionType === 'INVITE') {
    if (auth.shipmentId !== shipmentId || !auth.participantId) {
      throw forbidden('Invite session is scoped to a different shipment');
    }
    const participant = await prisma.shipmentParticipant.findUnique({
      where: { id: auth.participantId }
    });
    if (!participant || participant.shipmentId !== shipmentId) {
      throw forbidden('Invite access is no longer valid');
    }
    return {
      participant,
      permissions: asPermissions(
        participant.permissions,
        permissionTemplates[participant.participantRole]
      ),
      isAdmin: false
    };
  }

  if (!auth.userId) {
    throw unauthorized();
  }

  const participant = await prisma.shipmentParticipant.findFirst({
    where: {
      shipmentId,
      userId: auth.userId
    },
    orderBy: {
      createdAt: 'asc'
    }
  });

  if (!participant) {
    throw forbidden('You are not a participant on this shipment');
  }

  return {
    participant,
    permissions: asPermissions(participant.permissions, permissionTemplates[participant.participantRole]),
    isAdmin: false
  };
};

export const assertCan = (access: ShipmentAccess, permission: string) => {
  if (!access.isAdmin && !access.permissions[permission]) {
    throw forbidden(`Missing permission: ${permission}`);
  }
};

export const actorRole = (access?: ShipmentAccess) =>
  access?.participant?.participantRole ?? 'BROKER';

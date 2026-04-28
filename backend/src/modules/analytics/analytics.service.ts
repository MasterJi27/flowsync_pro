import { Prisma, StepStatus } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { forbidden, unauthorized } from '../../shared/errors';
import { AuthContext } from '../../types/express';

export class AnalyticsService {
  async delays(auth: AuthContext | undefined) {
    const shipmentWhere = await this.analyticsShipmentWhere(auth);
    const shipments = await prisma.shipment.findMany({
      where: shipmentWhere,
      select: { id: true }
    });
    const shipmentIds = shipments.map((shipment) => shipment.id);

    const steps = await prisma.shipmentStep.findMany({
      where: { shipmentId: { in: shipmentIds } }
    });

    const delayed = steps.filter((step) => {
      const actual = step.actualTime ?? new Date();
      return step.status === StepStatus.NEEDS_CONFIRMATION ||
        step.status === StepStatus.ESCALATED ||
        step.status === StepStatus.BLOCKED ||
        actual.getTime() > step.expectedTime.getTime();
    });

    const totalDelayMinutes = delayed.reduce((sum, step) => {
      const actual = step.actualTime ?? new Date();
      return sum + Math.max(0, Math.round((actual.getTime() - step.expectedTime.getTime()) / 60000));
    }, 0);

    return {
      totalSteps: steps.length,
      delayedSteps: delayed.length,
      delayPercent: steps.length ? Math.round((delayed.length / steps.length) * 1000) / 10 : 0,
      averageDelayMinutes: delayed.length ? Math.round(totalDelayMinutes / delayed.length) : 0,
      needsConfirmation: steps.filter((step) => step.status === StepStatus.NEEDS_CONFIRMATION).length
    };
  }

  async performance(auth: AuthContext | undefined) {
    const shipmentWhere = await this.analyticsShipmentWhere(auth);
    const [shipments, steps, escalations] = await Promise.all([
      prisma.shipment.findMany({ where: shipmentWhere }),
      prisma.shipmentStep.findMany({
        where: { shipment: { is: shipmentWhere } }
      }),
      prisma.escalationAttempt.count({
        where: { shipment: { is: shipmentWhere } }
      })
    ]);

    const completedShipments = shipments.filter((shipment) => shipment.currentStatus === 'COMPLETED').length;
    const confirmedSteps = steps.filter((step) => step.actualTime);
    const confirmationMinutes = confirmedSteps.map((step) =>
      Math.max(0, Math.round(((step.actualTime ?? new Date()).getTime() - step.expectedTime.getTime()) / 60000))
    );

    return {
      activeShipments: shipments.filter((shipment) =>
        ['PLANNED', 'IN_TRANSIT', 'NEEDS_CONFIRMATION', 'ESCALATED', 'DELAYED'].includes(shipment.currentStatus)
      ).length,
      completedShipments,
      completionRate: shipments.length ? Math.round((completedShipments / shipments.length) * 1000) / 10 : 0,
      averageConfirmationMinutes: confirmationMinutes.length
        ? Math.round(confirmationMinutes.reduce((sum, value) => sum + value, 0) / confirmationMinutes.length)
        : 0,
      escalationFrequency: shipments.length ? Math.round((escalations / shipments.length) * 100) / 100 : 0
    };
  }

  async reliability(auth: AuthContext | undefined) {
    const shipmentWhere = await this.analyticsShipmentWhere(auth);
    const participants = await prisma.shipmentParticipant.findMany({
      where: {
        shipment: { is: shipmentWhere },
        participantRole: 'TRANSPORTER'
      },
      include: {
        user: true,
        shipment: true
      },
      orderBy: [{ reliabilityScore: 'desc' }, { responseRate: 'desc' }]
    });

    const averageReliability = participants.length
      ? Math.round(
          participants.reduce((sum, participant) => sum + Number(participant.reliabilityScore), 0) /
            participants.length
        )
      : 0;

    return {
      averageReliability,
      transporters: participants.map((participant) => ({
        participantId: participant.id,
        shipmentId: participant.shipmentId,
        shipmentReference: participant.shipment.referenceNumber,
        name: participant.user?.name ?? participant.invitePhone ?? 'External transporter',
        phone: participant.user?.phone ?? participant.invitePhone,
        reliabilityScore: Number(participant.reliabilityScore),
        responseRate: Number(participant.responseRate),
        inviteStatus: participant.inviteStatus,
        lastActivityAt: participant.lastActivityAt
      }))
    };
  }

  private async analyticsShipmentWhere(auth: AuthContext | undefined): Promise<Prisma.ShipmentWhereInput> {
    if (!auth) {
      throw unauthorized();
    }
    if (auth.sessionType === 'INVITE') {
      throw forbidden('Temporary invite sessions cannot access analytics');
    }
    if (auth.globalRole === 'ADMIN') {
      return {};
    }
    if (!auth.userId) {
      throw unauthorized();
    }

    const participantCount = await prisma.shipmentParticipant.count({
      where: {
        userId: auth.userId,
        permissions: {
          path: ['analytics.read'],
          equals: true
        }
      }
    });
    if (participantCount === 0) {
      throw forbidden('Analytics permission is required');
    }

    return {
      participants: {
        some: {
          userId: auth.userId,
          permissions: {
            path: ['analytics.read'],
            equals: true
          }
        }
      }
    };
  }
}

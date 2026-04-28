import { prisma } from '../config/prisma';
import { logger } from '../config/logger';

/**
 * Get dispatch recommendation based on shipment and step status
 * Returns dispatch timing, risk level, and guidance
 */
export const getDispatchRecommendation = async (shipmentId: string) => {
  try {
    const shipment = await prisma.shipment.findUnique({
      where: { id: shipmentId }
    });

    if (!shipment) {
      return {
        error: 'Shipment not found',
        recommended_dispatch_time: null,
        risk_level: 'unknown',
        message: 'Unable to determine recommendation'
      };
    }

    const now = new Date();

    // Determine risk based on shipment status
    let riskLevel = 'low';
    let delayMinutes = 0;
    let message = '';

    if (shipment.currentStatus === 'NEEDS_CONFIRMATION') {
      riskLevel = 'high';
      message = '⚠️ Shipment needs confirmation before dispatch';
      delayMinutes = 15;
    } else if (shipment.currentStatus === 'IN_TRANSIT') {
      riskLevel = 'low';
      message = '✅ Shipment ready for dispatch';
      delayMinutes = 5;
    } else if (shipment.currentStatus === 'DELAYED') {
      riskLevel = 'medium';
      message = '⏱️ Shipment delayed - check status';
      delayMinutes = 0;
    } else {
      riskLevel = 'medium';
      message = '⏳ Awaiting status update';
      delayMinutes = 20;
    }

    // Calculate recommended dispatch time
    const recommendedDispatchTime = new Date(now.getTime() + delayMinutes * 60000);

    return {
      shipmentId,
      recommended_dispatch_time: recommendedDispatchTime.toISOString(),
      recommended_delay_minutes: delayMinutes,
      risk_level: riskLevel,
      message,
      shipment_status: shipment.currentStatus,
      current_step_id: shipment.currentStepId
    };
  } catch (error) {
    logger.error({ error: String(error), shipmentId }, 'Error calculating dispatch recommendation');
    return {
      error: String(error),
      recommended_dispatch_time: null,
      risk_level: 'unknown',
      message: 'Unable to determine recommendation'
    };
  }
};

/**
 * Estimate delay impact based on current status
 */
export const estimateDelayImpact = async (shipmentId: string) => {
  try {
    const shipment = await prisma.shipment.findUnique({
      where: { id: shipmentId }
    });

    if (!shipment) return null;

    const now = new Date();
    const createdTime = shipment.createdAt;
    const delayMs = now.getTime() - createdTime.getTime();
    const delayMinutes = Math.floor(delayMs / 60000);

    // Estimate impact
    let estimatedDelayHours = 0;
    let potentialCostImpact = 0;

    if (delayMinutes > 45) {
      estimatedDelayHours = Math.ceil(delayMinutes / 60);
      potentialCostImpact = estimatedDelayHours * 500; // ₹500 per hour
    } else if (delayMinutes > 20) {
      estimatedDelayHours = 1;
      potentialCostImpact = 250;
    }

    return {
      shipmentId,
      delay_minutes: delayMinutes,
      estimated_delay_hours: estimatedDelayHours,
      potential_cost_impact: potentialCostImpact,
      risk_color: estimatedDelayHours > 2 ? 'red' : estimatedDelayHours > 0 ? 'yellow' : 'green'
    };
  } catch (error) {
    logger.error({ error, shipmentId }, 'Error estimating delay impact');
    return null;
  }
};

/**
 * Get best contact for reaching out (highest trust score)
 */
export const getBestContact = async (shipmentId: string) => {
  try {
    const bestContact = await prisma.contact.findFirst({
      where: { shipmentId },
      include: { user: true },
      orderBy: { trustScore: 'desc' },
      take: 1
    });

    if (!bestContact) return null;

    const trustScoreNum = Number(bestContact.trustScore);
    return {
      contactId: bestContact.id,
      userId: bestContact.user?.id,
      name: bestContact.user?.name || 'Unknown',
      phone: bestContact.user?.phone || '',
      trustScore: trustScoreNum,
      responseTimeAvg: Number(bestContact.responseTimeAvg || 0),
      escalationOrder: bestContact.escalationOrder,
      trustLevel: trustScoreNum >= 75 ? 'high' : trustScoreNum >= 50 ? 'medium' : 'low'
    };
  } catch (error) {
    logger.error({ error: String(error), shipmentId }, 'Error getting best contact');
    return null;
  }
};

/**
 * Calculate transport readiness score (0-100)
 */
export const calculateTransportReadiness = async (shipmentId: string) => {
  try {
    const shipment = await prisma.shipment.findUnique({
      where: { id: shipmentId }
    });

    if (!shipment) return { score: 0, factors: {} };

    let score = 0;
    const factors = {
      shipment_exists: 25,
      shipment_active: shipment.currentStatus === 'IN_TRANSIT' ? 25 : 0,
      shipment_not_escalated: shipment.currentStatus !== 'CANCELLED' ? 25 : 0,
      no_pending_issues: true ? 25 : 0
    };

    score = Object.values(factors).reduce((a: number, b: any) => a + b, 0);

    return {
      shipmentId,
      readiness_score: score,
      is_ready: score >= 75,
      factors
    };
  } catch (error) {
    logger.error({ error: String(error), shipmentId }, 'Error calculating transport readiness');
    return { shipmentId, score: 0, error: String(error) };
  }
};

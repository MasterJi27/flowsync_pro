import cron from 'node-cron';
import { EscalationStatus, StepStatus } from '@prisma/client';
import { prisma } from '../config/prisma';
import { env } from '../config/env';
import { logger } from '../config/logger';
import { EscalationService } from '../modules/escalations/escalation.service';

const escalationService = new EscalationService();

export const startConfirmationSweep = () => {
  const task = cron.schedule(env.OVERDUE_SWEEP_CRON, async () => {
    try {
      const overdueSteps = await prisma.shipmentStep.findMany({
        where: {
          expectedTime: { lt: new Date() },
          actualTime: null,
          status: { in: [StepStatus.PENDING, StepStatus.IN_PROGRESS] },
          escalationStatus: EscalationStatus.NONE
        },
        take: 50,
        orderBy: { expectedTime: 'asc' }
      });

      for (const step of overdueSteps) {
        await escalationService.triggerSystem({
          shipmentId: step.shipmentId,
          stepId: step.id,
          reason: 'Expected time exceeded and no valid operational update exists'
        });
      }

      await escalationService.advanceStaleEscalations();
    } catch (error) {
      logger.error(error, 'Confirmation sweep failed');
    }
  });

  return task;
};

import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import { corsOrigins, env } from './config/env';
import { logger } from './config/logger';
import { prisma } from './config/prisma';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { apiLimiter, authLimiter } from './middleware/security';
import { analyticsRoutes } from './modules/analytics/analytics.routes';
import { authRoutes } from './modules/auth/auth.routes';
import { contactRoutes } from './modules/contacts/contact.routes';
import { escalationRoutes } from './modules/escalations/escalation.routes';
import { logRoutes } from './modules/logs/log.routes';
import { participantRoutes } from './modules/participants/participant.routes';
import { shipmentRoutes } from './modules/shipments/shipment.routes';
import { stepRoutes } from './modules/steps/step.routes';
import { transportRoutes } from './modules/transport/transport.routes';
import { asyncHandler } from './shared/asyncHandler';

export const createApp = () => {
  const app = express();

  app.set('trust proxy', env.TRUST_PROXY ? 1 : false);
  app.use(helmet());
  app.use(
    cors({
      origin: corsOrigins,
      credentials: true
    })
  );
  app.use(express.json({ limit: '2mb' }));
  app.use(
    pinoHttp({
      logger
    })
  );
  app.use(apiLimiter);

  app.get(
    '/health',
    asyncHandler(async (_req, res) => {
      await prisma.$queryRaw`SELECT 1`;
      res.json({
        status: 'ok',
        service: 'flowsync-pro-backend',
        timestamp: new Date().toISOString()
      });
    })
  );

  app.use('/auth', authLimiter, authRoutes);
  app.use('/shipments', shipmentRoutes);
  app.use(participantRoutes);
  app.use(stepRoutes);
  app.use(logRoutes);
  app.use(escalationRoutes);
  app.use(contactRoutes);
  app.use('/transport', transportRoutes);
  app.use(analyticsRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};

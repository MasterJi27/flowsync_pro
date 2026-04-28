import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import {
  delayAnalytics,
  performanceAnalytics,
  reliabilityAnalytics
} from './analytics.controller';

export const analyticsRoutes = Router();

analyticsRoutes.use(requireAuth);
analyticsRoutes.get('/analytics/delays', delayAnalytics);
analyticsRoutes.get('/analytics/performance', performanceAnalytics);
analyticsRoutes.get('/analytics/reliability', reliabilityAnalytics);

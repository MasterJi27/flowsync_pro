import { Request, Response } from 'express';
import { asyncHandler } from '../../shared/asyncHandler';
import { AnalyticsService } from './analytics.service';

const service = new AnalyticsService();

export const delayAnalytics = asyncHandler(async (req: Request, res: Response) => {
  res.json(await service.delays(req.auth));
});

export const performanceAnalytics = asyncHandler(async (req: Request, res: Response) => {
  res.json(await service.performance(req.auth));
});

export const reliabilityAnalytics = asyncHandler(async (req: Request, res: Response) => {
  res.json(await service.reliability(req.auth));
});

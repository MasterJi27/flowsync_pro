import { Request, Response } from 'express';
import { asyncHandler } from '../../shared/asyncHandler';
import { EscalationService } from './escalation.service';

const service = new EscalationService();

export const triggerEscalation = asyncHandler(async (req: Request, res: Response) => {
  const attempts = await service.trigger(req.auth, req.body);
  res.status(201).json(attempts);
});

export const listEscalations = asyncHandler(async (req: Request, res: Response) => {
  const attempts = await service.list(req.auth, req.params.shipmentId as string);
  res.json(attempts);
});

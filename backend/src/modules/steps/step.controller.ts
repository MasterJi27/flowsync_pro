import { Request, Response } from 'express';
import { asyncHandler } from '../../shared/asyncHandler';
import { StepService } from './step.service';

const service = new StepService();

export const createStep = asyncHandler(async (req: Request, res: Response) => {
  const step = await service.create(req.auth, req.params.id as string, req.body);
  res.status(201).json(step);
});

export const updateStep = asyncHandler(async (req: Request, res: Response) => {
  const step = await service.update(req.auth, req.params.id as string, req.body);
  res.json(step);
});

export const listSteps = asyncHandler(async (req: Request, res: Response) => {
  const steps = await service.list(req.auth, req.params.id as string);
  res.json(steps);
});

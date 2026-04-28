import { Request, Response } from 'express';
import { asyncHandler } from '../../shared/asyncHandler';
import { LogService } from './log.service';

const service = new LogService();

export const createLog = asyncHandler(async (req: Request, res: Response) => {
  const log = await service.create(req.auth, req.body);
  res.status(201).json(log);
});

export const listLogs = asyncHandler(async (req: Request, res: Response) => {
  const logs = await service.list(req.auth, req.params.shipmentId as string);
  res.json(logs);
});

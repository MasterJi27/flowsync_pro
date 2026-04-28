import { Request, Response } from 'express';
import { asyncHandler } from '../../shared/asyncHandler';
import { AuthService } from './auth.service';

const service = new AuthService();

export const register = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.register(req.body);
  res.status(201).json(result);
});

export const login = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.login(req.body);
  res.json(result);
});

export const inviteAccess = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.inviteAccess(req.body);
  res.json(result);
});

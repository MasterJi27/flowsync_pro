import { Request, Response } from 'express';
import rateLimit from 'express-rate-limit';
import { asyncHandler } from '../../shared/asyncHandler';
import { AuthServiceEnhanced } from './auth.service.enhanced';

export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many authentication attempts, please try again later.'
});

const service = new AuthServiceEnhanced();

export const register = [
  authLimiter,
  asyncHandler(async (req: Request, res: Response) => {
    const result = await service.register(
      req.body,
      req.ip,
      req.get('User-Agent')
    );
    res.status(201).json(result);
  })
];

export const login = [
  authLimiter,
  asyncHandler(async (req: Request, res: Response) => {
    const result = await service.login(
      req.body,
      req.ip,
      req.get('User-Agent')
    );
    res.json(result);
  })
];

export const firebaseLogin = [
  authLimiter,
  asyncHandler(async (req: Request, res: Response) => {
    const result = await service.firebaseLogin(
      req.body,
      req.ip,
      req.get('User-Agent')
    );
    res.json(result);
  })
];

export const inviteAccess = [
  authLimiter,
  asyncHandler(async (req: Request, res: Response) => {
    const result = await service.inviteAccess(
      req.body,
      req.ip,
      req.get('User-Agent')
    );
    res.json(result);
  })
];

export const logout = [
  asyncHandler(async (req: Request, res: Response) => {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid token' });
    }

    const token = authHeader.substring(7);
    await service.logout(token);
    res.json({ success: true });
  })
];

export const refreshToken = [
  asyncHandler(async (req: Request, res: Response) => {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }

    const result = await service.refreshToken(refreshToken);
    res.json(result);
  })
];

export const getCurrentUser = [
  asyncHandler(async (req: Request, res: Response) => {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid token' });
    }

    const token = authHeader.substring(7);
    const user = await service.getCurrentUser(token);
    res.json({ user });
  })
];
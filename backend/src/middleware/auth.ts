import { NextFunction, Request, Response } from 'express';
import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';
import { unauthorized } from '../shared/errors';
import { AuthContext } from '../types/express';

export const signSessionToken = (payload: AuthContext) =>
  jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN as SignOptions['expiresIn']
  });

export const verifySessionToken = (token: string): AuthContext =>
  jwt.verify(token, env.JWT_SECRET) as AuthContext;

export const requireAuth = (req: Request, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return next(unauthorized());
  }

  try {
    req.auth = jwt.verify(header.slice(7), env.JWT_SECRET) as AuthContext;
    return next();
  } catch {
    return next(unauthorized('Invalid or expired token'));
  }
};

export const optionalAuth = (req: Request, _res: Response, next: NextFunction) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return next();
  }

  try {
    req.auth = jwt.verify(header.slice(7), env.JWT_SECRET) as AuthContext;
  } catch {
    req.auth = undefined;
  }
  return next();
};

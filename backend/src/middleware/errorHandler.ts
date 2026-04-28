import { NextFunction, Request, Response } from 'express';
import { Prisma } from '@prisma/client';
import { logger } from '../config/logger';
import { AppError } from '../shared/errors';

export const notFoundHandler = (req: Request, res: Response) => {
  res.status(404).json({
    error: {
      code: 'ROUTE_NOT_FOUND',
      message: `${req.method} ${req.path} is not registered`
    }
  });
};

export const errorHandler = (
  error: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message,
        details: error.details
      }
    });
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      return res.status(409).json({
        error: {
          code: 'UNIQUE_CONSTRAINT',
          message: 'A record with these unique fields already exists',
          details: error.meta
        }
      });
    }
  }

  logger.error(error, 'Unhandled request error');
  return res.status(500).json({
    error: {
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Unexpected server error'
    }
  });
};

import { NextFunction, Request, Response } from 'express';
import { z, ZodError } from 'zod';
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type RequestSchema = z.ZodObject<any>;
import { AppError } from '../shared/errors';

export const validate =
  (schema: RequestSchema) => (req: Request, _res: Response, next: NextFunction) => {
    try {
      const parsed = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params
      });
      req.body = parsed.body ?? req.body;
      req.query = (parsed.query ?? req.query) as Request['query'];
      req.params = (parsed.params ?? req.params) as Request['params'];
      return next();
    } catch (error) {
      if (error instanceof ZodError) {
        return next(
          new AppError(422, 'VALIDATION_FAILED', 'Request validation failed', error.flatten())
        );
      }
      return next(error);
    }
  };

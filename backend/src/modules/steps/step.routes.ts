import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createStep, listSteps, updateStep } from './step.controller';
import { createStepSchema, shipmentStepsParams, updateStepSchema } from './step.validation';

export const stepRoutes = Router();

stepRoutes.use(requireAuth);
stepRoutes.post('/shipments/:id/steps', validate(createStepSchema), createStep);
stepRoutes.get('/shipments/:id/steps', validate(shipmentStepsParams), listSteps);
stepRoutes.patch('/steps/:id', validate(updateStepSchema), updateStep);

import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createLog, listLogs } from './log.controller';
import { createLogSchema, logShipmentParams } from './log.validation';

export const logRoutes = Router();

logRoutes.use(requireAuth);
logRoutes.post('/logs', validate(createLogSchema), createLog);
logRoutes.get('/logs/:shipmentId', validate(logShipmentParams), listLogs);

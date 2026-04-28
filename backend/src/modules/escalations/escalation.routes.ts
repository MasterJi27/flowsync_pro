import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { listEscalations, triggerEscalation } from './escalation.controller';
import { escalationShipmentParams, triggerEscalationSchema } from './escalation.validation';

export const escalationRoutes = Router();

escalationRoutes.use(requireAuth);
escalationRoutes.post('/escalations/trigger', validate(triggerEscalationSchema), triggerEscalation);
escalationRoutes.get('/escalations/:shipmentId', validate(escalationShipmentParams), listEscalations);

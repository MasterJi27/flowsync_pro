import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { addParticipant, inviteTransporter, listParticipants } from './participant.controller';
import {
  addParticipantSchema,
  inviteTransporterSchema,
  shipmentParticipantParams
} from './participant.validation';

export const participantRoutes = Router();

participantRoutes.use(requireAuth);
participantRoutes.get('/shipments/:id/participants', validate(shipmentParticipantParams), listParticipants);
participantRoutes.post('/shipments/:id/participants', validate(addParticipantSchema), addParticipant);
participantRoutes.post(
  '/shipments/:id/invite-transporter',
  validate(inviteTransporterSchema),
  inviteTransporter
);

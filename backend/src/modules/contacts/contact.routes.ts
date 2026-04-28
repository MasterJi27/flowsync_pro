import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createContact, listContacts } from './contact.controller';
import { contactShipmentParams, createContactSchema } from './contact.validation';

export const contactRoutes = Router();

contactRoutes.use(requireAuth);
contactRoutes.post('/contacts', validate(createContactSchema), createContact);
contactRoutes.get('/contacts/:shipmentId', validate(contactShipmentParams), listContacts);

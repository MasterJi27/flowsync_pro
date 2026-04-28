import { Router } from 'express';
import { requireAuth } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import {
  createShipment,
  deleteShipment,
  getShipment,
  listShipments,
  updateShipment
} from './shipment.controller';
import {
  createShipmentSchema,
  listShipmentsSchema,
  shipmentIdSchema,
  updateShipmentSchema
} from './shipment.validation';

export const shipmentRoutes = Router();

shipmentRoutes.use(requireAuth);
shipmentRoutes.post('/', validate(createShipmentSchema), createShipment);
shipmentRoutes.get('/', validate(listShipmentsSchema), listShipments);
shipmentRoutes.get('/:id', validate(shipmentIdSchema), getShipment);
shipmentRoutes.patch('/:id', validate(updateShipmentSchema), updateShipment);
shipmentRoutes.delete('/:id', validate(shipmentIdSchema), deleteShipment);

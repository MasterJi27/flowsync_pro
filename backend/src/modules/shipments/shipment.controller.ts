import { Request, Response } from 'express';
import { asyncHandler } from '../../shared/asyncHandler';
import { ShipmentService } from './shipment.service';

const service = new ShipmentService();

export const createShipment = asyncHandler(async (req: Request, res: Response) => {
  const shipment = await service.create(req.auth, req.body);
  res.status(201).json(shipment);
});

export const listShipments = asyncHandler(async (req: Request, res: Response) => {
  const result = await service.list(req.auth, req.query);
  res.json(result);
});

export const getShipment = asyncHandler(async (req: Request, res: Response) => {
  const shipment = await service.get(req.auth, req.params.id as string);
  res.json(shipment);
});

export const updateShipment = asyncHandler(async (req: Request, res: Response) => {
  const shipment = await service.update(req.auth, req.params.id as string, req.body);
  res.json(shipment);
});

export const deleteShipment = asyncHandler(async (req: Request, res: Response) => {
  const shipment = await service.cancel(req.auth, req.params.id as string);
  res.json(shipment);
});

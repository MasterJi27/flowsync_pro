import { Request, Response } from 'express';
import { asyncHandler } from '../../shared/asyncHandler';
import { ContactService } from './contact.service';

const service = new ContactService();

export const createContact = asyncHandler(async (req: Request, res: Response) => {
  const contact = await service.create(req.auth, req.body);
  res.status(201).json(contact);
});

export const listContacts = asyncHandler(async (req: Request, res: Response) => {
  const contacts = await service.list(req.auth, req.params.shipmentId as string);
  res.json(contacts);
});

import { Request, Response } from 'express';
import { asyncHandler } from '../../shared/asyncHandler';
import { ParticipantService } from './participant.service';

const service = new ParticipantService();

export const listParticipants = asyncHandler(async (req: Request, res: Response) => {
  const participants = await service.list(req.auth, req.params.id as string);
  res.json(participants);
});

export const addParticipant = asyncHandler(async (req: Request, res: Response) => {
  const participant = await service.add(req.auth, req.params.id as string, req.body);
  res.status(201).json(participant);
});

export const inviteTransporter = asyncHandler(async (req: Request, res: Response) => {
  const invite = await service.inviteTransporter(req.auth, req.params.id as string, req.body);
  res.status(201).json(invite);
});

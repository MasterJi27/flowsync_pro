import { ParticipantRole, StepStatus, UpdateSource } from '@prisma/client';
import { prisma } from '../config/prisma';

const clamp = (value: number, min: number, max: number) => Math.min(Math.max(value, min), max);

export const sourceForRole = (role: ParticipantRole): UpdateSource => {
  if (role === 'BROKER') return 'BROKER';
  if (role === 'AUTHORITY') return 'AUTHORITY';
  return 'TRANSPORTER';
};

export const confidenceForUpdate = (
  role: ParticipantRole,
  reliabilityScore: number,
  explicitConfidence?: number
) => {
  if (explicitConfidence !== undefined) {
    return clamp(explicitConfidence, 0, 100);
  }

  const sourceBase: Record<ParticipantRole, number> = {
    BROKER: 86,
    CLIENT: 55,
    TRANSPORTER: 70,
    AUTHORITY: 90
  };

  return Math.round(clamp(sourceBase[role] + (reliabilityScore - 50) * 0.25, 35, 99));
};

export const updateParticipantReliability = async (input: {
  participantId?: string;
  stepId: string;
  status: StepStatus;
  isFirstConfirmation: boolean;
}) => {
  if (!input.participantId) return undefined;

  const participant = await prisma.shipmentParticipant.findUnique({
    where: { id: input.participantId }
  });
  const step = await prisma.shipmentStep.findUnique({
    where: { id: input.stepId }
  });
  if (!participant || !step) return undefined;

  const currentScore = Number(participant.reliabilityScore);
  const currentRate = Number(participant.responseRate);
  const now = step.actualTime ?? new Date();
  const lateMinutes = Math.max(0, Math.round((now.getTime() - step.expectedTime.getTime()) / 60000));
  const completed = input.status === 'COMPLETED' || input.status === 'IN_PROGRESS';
  const latePenalty = Math.min(12, Math.floor(lateMinutes / 30));
  const firstBonus = input.isFirstConfirmation ? 8 : 1;
  const completionBonus = completed ? 3 : 0;
  const score = clamp(currentScore + firstBonus + completionBonus - latePenalty, 0, 100);
  const responseRate = clamp(currentRate * 0.85 + (completed ? 100 : 20) * 0.15, 0, 100);

  return prisma.shipmentParticipant.update({
    where: { id: input.participantId },
    data: {
      reliabilityScore: score,
      responseRate,
      lastActivityAt: new Date()
    }
  });
};

export const penalizeMissedParticipant = async (participantId?: string) => {
  if (!participantId) return undefined;
  const participant = await prisma.shipmentParticipant.findUnique({ where: { id: participantId } });
  if (!participant) return undefined;

  return prisma.shipmentParticipant.update({
    where: { id: participantId },
    data: {
      reliabilityScore: clamp(Number(participant.reliabilityScore) - 4, 0, 100),
      responseRate: clamp(Number(participant.responseRate) * 0.95, 0, 100)
    }
  });
};

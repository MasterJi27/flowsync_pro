import { GlobalRole, ParticipantRole } from '@prisma/client';

export type AuthContext = {
  sessionType: 'USER' | 'INVITE';
  userId?: string;
  participantId?: string;
  shipmentId?: string;
  globalRole?: GlobalRole;
  role?: ParticipantRole;
};

declare global {
  namespace Express {
    interface Request {
      auth?: AuthContext;
    }
  }
}

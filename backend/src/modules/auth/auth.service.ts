import bcrypt from 'bcryptjs';
import { ParticipantInviteStatus, SourceType } from '@prisma/client';
import { prisma } from '../../config/prisma';
import { permissionTemplates } from '../../constants/permissions';
import { signSessionToken } from '../../middleware/auth';
import { AppError, unauthorized } from '../../shared/errors';
import { AuthRepository } from './auth.repository';

type RegisterInput = {
  name: string;
  phone: string;
  email: string;
  password: string;
  globalRole: 'BROKER' | 'CLIENT' | 'TRANSPORTER' | 'AUTHORITY' | 'ADMIN';
  inviteToken?: string;
};

type LoginInput = {
  emailOrPhone: string;
  password: string;
};

type InviteAccessInput = {
  token: string;
  phone?: string;
};

export class AuthService {
  constructor(private readonly repo = new AuthRepository()) {}

  async register(input: RegisterInput) {
    const passwordHash = await bcrypt.hash(input.password, 12);

    const user = await this.repo.createUser({
      name: input.name,
      phone: input.phone,
      email: input.email.toLowerCase(),
      passwordHash,
      globalRole: input.globalRole
    });

    if (input.inviteToken) {
      const invite = await this.repo.findInviteByToken(input.inviteToken);
      if (!invite) {
        throw new AppError(404, 'INVITE_NOT_FOUND', 'Invite token was not found');
      }
      if (invite.inviteExpiresAt && invite.inviteExpiresAt < new Date()) {
        throw new AppError(410, 'INVITE_EXPIRED', 'Invite token has expired');
      }
      await this.repo.linkInviteToUser(input.inviteToken, user.id);
      await prisma.shipmentLog.create({
        data: {
          shipmentId: invite.shipmentId,
          performedBy: user.id,
          performerRole: invite.participantRole,
          action: 'PARTICIPANT_JOINED',
          notes: `${user.name} completed account onboarding from invite`,
          sourceType: SourceType.USER,
          confidenceScore: 80
        }
      });
    }

    const token = signSessionToken({
      sessionType: 'USER',
      userId: user.id,
      globalRole: user.globalRole,
      role: input.globalRole === 'ADMIN' ? 'BROKER' : (input.globalRole as Exclude<typeof input.globalRole, 'ADMIN'>)
    });

    return {
      token,
      user: this.publicUser(user)
    };
  }

  async login(input: LoginInput) {
    const user = await this.repo.findUserByEmailOrPhone(input.emailOrPhone.toLowerCase());
    if (!user) {
      throw unauthorized('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(input.password, user.passwordHash);
    if (!isPasswordValid) {
      throw unauthorized('Invalid credentials');
    }

    const token = signSessionToken({
      sessionType: 'USER',
      userId: user.id,
      globalRole: user.globalRole,
      role: user.globalRole === 'ADMIN' ? 'BROKER' : (user.globalRole as Exclude<typeof user.globalRole, 'ADMIN'>)
    });

    return {
      token,
      user: this.publicUser(user)
    };
  }

  async inviteAccess(input: InviteAccessInput) {
    const invite = await this.repo.findInviteByToken(input.token);
    if (!invite) {
      throw unauthorized('Invalid invite token');
    }

    if (invite.inviteStatus === ParticipantInviteStatus.REVOKED) {
      throw new AppError(410, 'INVITE_REVOKED', 'Invite token has been revoked');
    }

    if (invite.inviteExpiresAt && invite.inviteExpiresAt < new Date()) {
      await prisma.shipmentParticipant.update({
        where: { id: invite.id },
        data: { inviteStatus: ParticipantInviteStatus.EXPIRED }
      });
      throw new AppError(410, 'INVITE_EXPIRED', 'Invite token has expired');
    }

    if (input.phone && invite.invitePhone && input.phone !== invite.invitePhone) {
      throw unauthorized('Phone number does not match invite');
    }

    const wasPending = invite.inviteStatus === ParticipantInviteStatus.PENDING;
    const participant = await prisma.shipmentParticipant.update({
      where: { id: invite.id },
      data: {
        inviteStatus: ParticipantInviteStatus.JOINED,
        joinedAt: invite.joinedAt ?? new Date(),
        lastActivityAt: new Date(),
        permissions: invite.permissions ?? permissionTemplates.TRANSPORTER
      }
    });

    if (wasPending) {
      await prisma.shipmentLog.create({
        data: {
          shipmentId: invite.shipmentId,
          performerRole: participant.participantRole,
          action: 'PARTICIPANT_JOINED',
          notes: `Transporter joined through secure invite for ${invite.invitePhone}`,
          sourceType: SourceType.INVITE,
          confidenceScore: 70
        }
      });
    }

    const token = signSessionToken({
      sessionType: 'INVITE',
      participantId: participant.id,
      shipmentId: participant.shipmentId,
      role: participant.participantRole
    });

    return {
      token,
      participant,
      shipment: invite.shipment,
      permissions: participant.permissions
    };
  }

  private publicUser(user: {
    id: string;
    name: string;
    email: string;
    phone: string;
    globalRole: string;
    createdAt: Date;
  }) {
    return {
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      globalRole: user.globalRole,
      createdAt: user.createdAt
    };
  }
}

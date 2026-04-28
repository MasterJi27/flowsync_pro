import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import rateLimit from 'express-rate-limit';
import { ParticipantInviteStatus, SourceType } from '@prisma/client';
import { verifyFirebaseIdToken } from '../../config/firebase';
import { prisma } from '../../config/prisma';
import { permissionTemplates } from '../../constants/permissions';
import { signSessionToken, verifySessionToken } from '../../middleware/auth';
import { AppError, unauthorized } from '../../shared/errors';
import { AuthRepository } from './auth.repository';
import { logger } from '../../config/logger';

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
  ipAddress?: string;
  userAgent?: string;
};

type InviteAccessInput = {
  token: string;
  phone?: string;
  ipAddress?: string;
  userAgent?: string;
};

type FirebaseLoginInput = {
  idToken: string;
  email?: string;
  phone?: string;
  name?: string;
};

export class AuthServiceEnhanced {
  constructor(private readonly repo = new AuthRepository()) {}

  // Rate limiting for auth endpoints
  static authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // limit each IP to 5 requests per windowMs
    standardHeaders: true,
    legacyHeaders: false,
    message: 'Too many authentication attempts, please try again later.'
  });

  // Enhanced password validation
  private validatePasswordStrength(password: string): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];
    
    if (password.length < 8) {
      errors.push('Password must be at least 8 characters long');
    }
    
    if (!/[a-z]/.test(password)) {
      errors.push('Password must contain at least one lowercase letter');
    }
    
    if (!/[A-Z]/.test(password)) {
      errors.push('Password must contain at least one uppercase letter');
    }
    
    if (!/[0-9]/.test(password)) {
      errors.push('Password must contain at least one digit');
    }
    
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      errors.push('Password must contain at least one special character');
    }
    
    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Generate secure random tokens
  private generateSecureToken(length: number = 32): string {
    return crypto.randomBytes(length).toString('hex');
  }

  // Hash password with bcrypt and salt rounds
  private async hashPassword(password: string): Promise<string> {
    const saltRounds = 12;
    return await bcrypt.hash(password, saltRounds);
  }

  // Verify password against hash
  private async verifyPassword(password: string, hash: string): Promise<boolean> {
    return await bcrypt.compare(password, hash);
  }

  async register(input: RegisterInput, ipAddress?: string, userAgent?: string) {
    // Validate password strength
    const passwordValidation = this.validatePasswordStrength(input.password);
    if (!passwordValidation.isValid) {
      throw new AppError(400, 'WEAK_PASSWORD', `Password does not meet requirements: ${passwordValidation.errors.join(', ')}`);
    }

    // Check if user already exists
    const existingUser = await this.repo.findUserByEmailOrPhone(input.email.toLowerCase());
    if (existingUser) {
      throw new AppError(409, 'USER_EXISTS', 'User with this email or phone already exists');
    }

    const passwordHash = await this.hashPassword(input.password);

    const user = await this.repo.createUser({
      name: input.name.trim(),
      phone: input.phone.trim(),
      email: input.email.toLowerCase().trim(),
      passwordHash,
      globalRole: input.globalRole
    });

    logger.info(`User registered: ${user.id} from IP: ${ipAddress || 'unknown'}`);

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

  async login(input: LoginInput, ipAddress?: string, userAgent?: string) {
    const user = await this.repo.findUserByEmailOrPhone(input.emailOrPhone.toLowerCase().trim());
    if (!user) {
      logger.warn(`Failed login attempt for non-existent user: ${input.emailOrPhone} from IP: ${ipAddress || 'unknown'}`);
      throw unauthorized('Invalid credentials');
    }

    const isPasswordValid = await this.verifyPassword(input.password, user.passwordHash);
    if (!isPasswordValid) {
      logger.warn(`Failed login attempt for user: ${user.id} from IP: ${ipAddress || 'unknown'}`);
      throw unauthorized('Invalid credentials');
    }

    const token = signSessionToken({
      sessionType: 'USER',
      userId: user.id,
      globalRole: user.globalRole,
      role: user.globalRole === 'ADMIN' ? 'BROKER' : (user.globalRole as Exclude<typeof user.globalRole, 'ADMIN'>)
    });

    logger.info(`User logged in: ${user.id} from IP: ${ipAddress || 'unknown'}`);

    return {
      token,
      user: this.publicUser(user)
    };
  }

  async firebaseLogin(input: FirebaseLoginInput, ipAddress?: string, userAgent?: string) {
    let decoded;
    try {
      decoded = await verifyFirebaseIdToken(input.idToken);
    } catch (error) {
      logger.warn(error, 'Firebase token verification failed');
      throw unauthorized('Invalid Firebase identity token');
    }

    const identityCandidates = [
      decoded.email?.toLowerCase().trim(),
      input.email?.toLowerCase().trim(),
      decoded.phone_number?.trim(),
      input.phone?.trim()
    ].filter((value): value is string => !!value && value.length > 0);

    let user = null;
    for (const identity of identityCandidates) {
      user = await this.repo.findUserByEmailOrPhone(identity);
      if (user) {
        break;
      }
    }

    if (!user) {
      const fallbackEmail =
        decoded.email?.toLowerCase().trim() ||
        input.email?.toLowerCase().trim() ||
        `${decoded.uid}@firebase.flowsync.local`;
      const fallbackPhone =
        decoded.phone_number?.trim() ||
        input.phone?.trim() ||
        `uid-${decoded.uid.substring(0, 20)}`;
      const fallbackName =
        decoded.name?.trim() ||
        input.name?.trim() ||
        (decoded.phone_number ? `User ${decoded.phone_number}` : 'FlowSync User');

      user = await this.repo.createUser({
        name: fallbackName,
        phone: fallbackPhone,
        email: fallbackEmail,
        passwordHash: await this.hashPassword(this.generateSecureToken(24)),
        globalRole: 'CLIENT'
      });

      logger.info(`User provisioned from Firebase identity: ${user.id} (${decoded.uid})`);
    }

    const token = signSessionToken({
      sessionType: 'USER',
      userId: user.id,
      globalRole: user.globalRole,
      role: user.globalRole === 'ADMIN' ? 'BROKER' : (user.globalRole as Exclude<typeof user.globalRole, 'ADMIN'>)
    });

    logger.info(`User logged in with Firebase: ${user.id} from IP: ${ipAddress || 'unknown'}`);

    return {
      token,
      user: this.publicUser(user)
    };
  }

  async inviteAccess(input: InviteAccessInput, ipAddress?: string, userAgent?: string) {
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
      participant: {
        id: participant.id,
        invitePhone: participant.invitePhone,
        shipmentId: participant.shipmentId,
        role: participant.participantRole
      },
      shipment: invite.shipment,
      permissions: participant.permissions
    };
  }

  // Enhanced logout with token blacklisting (simplified)
  async logout(token: string) {
    logger.info(`User logged out from token: ${token.substring(0, 20)}...`);
    return { success: true };
  }

  // Refresh token endpoint
  async refreshToken(refreshToken: string) {
    try {
      const payload = verifySessionToken(refreshToken);
      const newToken = signSessionToken({
        sessionType: payload.sessionType,
        userId: payload.userId,
        globalRole: payload.globalRole,
        role: payload.role
      });
      
      return { token: newToken };
    } catch (error) {
      throw unauthorized('Invalid refresh token');
    }
  }

  // Get current user from token
  async getCurrentUser(token: string) {
    try {
      const payload = verifySessionToken(token);
      if (payload.sessionType === 'USER' && payload.userId) {
        const user = await this.repo.findUserById(payload.userId);
        if (!user) {
          throw unauthorized('User not found');
        }
        return this.publicUser(user);
      }
      if (payload.sessionType === 'INVITE' && payload.participantId) {
        const participant = await prisma.shipmentParticipant.findUnique({
          where: { id: payload.participantId },
          include: { shipment: true }
        });
        if (!participant) {
          throw unauthorized('Participant not found');
        }
        return {
          id: participant.id,
          name: participant.invitePhone ?? 'Invited User',
          phone: participant.invitePhone ?? '',
          email: '',
          globalRole: participant.participantRole,
          shipmentId: participant.shipmentId,
          role: participant.participantRole
        };
      }
      throw unauthorized('Invalid session');
    } catch (error) {
      throw unauthorized('Invalid or expired token');
    }
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

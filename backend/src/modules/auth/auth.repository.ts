import { Prisma, User } from '@prisma/client';
import { prisma } from '../../config/prisma';

export class AuthRepository {
  createUser(data: Prisma.UserCreateInput) {
    return prisma.user.create({ data });
  }

  findUserById(id: string): Promise<User | null> {
    return prisma.user.findUnique({ where: { id } });
  }

  findUserByEmailOrPhone(emailOrPhone: string): Promise<User | null> {
    return prisma.user.findFirst({
      where: {
        OR: [{ email: emailOrPhone }, { phone: emailOrPhone }]
      }
    });
  }

  findInviteByToken(token: string) {
    return prisma.shipmentParticipant.findUnique({
      where: { inviteToken: token },
      include: {
        shipment: true
      }
    });
  }

  linkInviteToUser(inviteToken: string, userId: string) {
    return prisma.shipmentParticipant.update({
      where: { inviteToken },
      data: {
        userId,
        inviteStatus: 'JOINED',
        joinedAt: new Date(),
        lastActivityAt: new Date()
      }
    });
  }
}

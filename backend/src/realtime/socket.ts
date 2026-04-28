import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import { Server } from 'socket.io';
import { env, corsOrigins } from '../config/env';
import { logger } from '../config/logger';
import { AuthContext } from '../types/express';

let io: Server | undefined;

export const initSocket = (server: HttpServer) => {
  io = new Server(server, {
    cors: {
      origin: corsOrigins,
      credentials: true
    }
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth.token as string | undefined;
    if (!token) {
      return next(new Error('Socket authentication token is required'));
    }
    try {
      socket.data.auth = jwt.verify(token, env.JWT_SECRET) as AuthContext;
      return next();
    } catch {
      return next(new Error('Invalid socket token'));
    }
  });

  io.on('connection', (socket) => {
    const auth = socket.data.auth as AuthContext;
    if (auth.userId) {
      socket.join(`user:${auth.userId}`);
    }
    if (auth.participantId) {
      socket.join(`participant:${auth.participantId}`);
    }

    socket.on('shipment:join', (shipmentId: string) => {
      if (auth.sessionType === 'INVITE' && auth.shipmentId !== shipmentId) {
        return;
      }
      socket.join(`shipment:${shipmentId}`);
    });

    socket.on('disconnect', (reason) => {
      logger.debug({ reason }, 'Socket disconnected');
    });
  });

  return io;
};

export const emitShipment = (shipmentId: string, event: string, payload: unknown) => {
  io?.to(`shipment:${shipmentId}`).emit(event, payload);
};

export const emitUser = (userId: string, event: string, payload: unknown) => {
  io?.to(`user:${userId}`).emit(event, payload);
};

export const emitParticipant = (participantId: string, event: string, payload: unknown) => {
  io?.to(`participant:${participantId}`).emit(event, payload);
};

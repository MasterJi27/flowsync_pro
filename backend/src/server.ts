import http from 'http';
import { createApp } from './app';
import { env } from './config/env';
import { logger } from './config/logger';
import { prisma } from './config/prisma';
import { startConfirmationSweep } from './jobs/confirmationSweep.job';
import { initSocket } from './realtime/socket';

const app = createApp();
const server = http.createServer(app);

initSocket(server);
const sweepTask = startConfirmationSweep();

server.listen(env.PORT, () => {
  logger.info({ port: env.PORT }, 'FlowSync Pro backend listening');
});

const shutdown = async (signal: string) => {
  logger.info({ signal }, 'Shutting down FlowSync Pro backend');
  sweepTask.stop();
  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

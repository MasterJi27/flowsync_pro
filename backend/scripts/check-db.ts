import { PrismaClient } from '@prisma/client';
import { logger } from '../src/config/logger';

const prisma = new PrismaClient();

async function main() {
  const result = await prisma.$queryRaw<Array<{ ok: number }>>`SELECT 1 AS ok`;
  if (!result.length || result[0].ok !== 1) {
    throw new Error('Database connectivity check returned an unexpected response');
  }

  const [{ version }] = await prisma.$queryRaw<Array<{ version: string }>>`SELECT version() AS version`;
  logger.info('Database connectivity check passed');
  logger.info({ version }, 'Connected database version');
}

main()
  .catch((error) => {
    logger.error({ error }, 'Database connectivity check failed');
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

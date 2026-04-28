import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { PrismaClient } from '@prisma/client';
import { logger } from '../src/config/logger';
import { permissionTemplates } from '../src/constants/permissions';

const prisma = new PrismaClient();

const password = async () => bcrypt.hash('Password123!', 12);

const minutesFromNow = (minutes: number) => new Date(Date.now() + minutes * 60 * 1000);

async function main() {
  const hashed = await password();

  const [broker, client, transporter, authority] = await Promise.all([
    prisma.user.upsert({
      where: { email: 'broker@flowsync.local' },
      update: {
        name: 'Ananya Broker',
        phone: '+919900000001',
        passwordHash: hashed,
        globalRole: 'BROKER'
      },
      create: {
        name: 'Ananya Broker',
        phone: '+919900000001',
        email: 'broker@flowsync.local',
        passwordHash: hashed,
        globalRole: 'BROKER'
      }
    }),
    prisma.user.upsert({
      where: { email: 'client@flowsync.local' },
      update: {
        name: 'Vikram Client',
        phone: '+919900000002',
        passwordHash: hashed,
        globalRole: 'CLIENT'
      },
      create: {
        name: 'Vikram Client',
        phone: '+919900000002',
        email: 'client@flowsync.local',
        passwordHash: hashed,
        globalRole: 'CLIENT'
      }
    }),
    prisma.user.upsert({
      where: { email: 'transporter@flowsync.local' },
      update: {
        name: 'Ravi Transporter',
        phone: '+919900000003',
        passwordHash: hashed,
        globalRole: 'TRANSPORTER'
      },
      create: {
        name: 'Ravi Transporter',
        phone: '+919900000003',
        email: 'transporter@flowsync.local',
        passwordHash: hashed,
        globalRole: 'TRANSPORTER'
      }
    }),
    prisma.user.upsert({
      where: { email: 'authority@flowsync.local' },
      update: {
        name: 'Meera Authority',
        phone: '+919900000004',
        passwordHash: hashed,
        globalRole: 'AUTHORITY'
      },
      create: {
        name: 'Meera Authority',
        phone: '+919900000004',
        email: 'authority@flowsync.local',
        passwordHash: hashed,
        globalRole: 'AUTHORITY'
      }
    })
  ]);

  let primaryShipment = await prisma.shipment.findUnique({
    where: { referenceNumber: 'FS-DEMO-DELHI-DXB-001' },
    include: {
      steps: { orderBy: { sequenceOrder: 'asc' } },
      participants: true
    }
  });

  if (!primaryShipment) {
    primaryShipment = await prisma.shipment.create({
      data: {
        referenceNumber: 'FS-DEMO-DELHI-DXB-001',
        origin: 'Delhi ICD',
        destination: 'Dubai Airport Free Zone',
        transportType: 'AIR',
        priorityLevel: 'CRITICAL',
        createdBy: broker.id,
        currentStatus: 'IN_TRANSIT',
        participants: {
          create: [
            {
              userId: broker.id,
              participantRole: 'BROKER',
              permissions: permissionTemplates.BROKER,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 96,
              responseRate: 100,
              lastActivityAt: new Date()
            },
            {
              userId: client.id,
              participantRole: 'CLIENT',
              permissions: permissionTemplates.CLIENT,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 82,
              responseRate: 100,
              lastActivityAt: new Date()
            },
            {
              userId: transporter.id,
              participantRole: 'TRANSPORTER',
              permissions: permissionTemplates.TRANSPORTER,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 74,
              responseRate: 71,
              lastActivityAt: minutesFromNow(-90)
            },
            {
              userId: authority.id,
              participantRole: 'AUTHORITY',
              permissions: permissionTemplates.AUTHORITY,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 88,
              responseRate: 93,
              lastActivityAt: minutesFromNow(-30)
            },
            {
              participantRole: 'TRANSPORTER',
              permissions: permissionTemplates.TRANSPORTER,
              inviteToken: crypto.randomBytes(32).toString('hex'),
              invitePhone: '+919900000099',
              inviteStatus: 'PENDING',
              inviteExpiresAt: minutesFromNow(60 * 24 * 7),
              reliabilityScore: 50,
              responseRate: 0
            }
          ]
        },
        steps: {
          create: [
            {
              stepName: 'Pickup',
              sequenceOrder: 1,
              expectedTime: minutesFromNow(-45),
              status: 'IN_PROGRESS',
              updateSource: 'TRANSPORTER',
              updatedBy: transporter.id,
              confidenceScore: 70,
              escalationStatus: 'NONE'
            },
            {
              stepName: 'Warehouse',
              sequenceOrder: 2,
              expectedTime: minutesFromNow(45),
              status: 'PENDING',
              confidenceScore: 60
            },
            {
              stepName: 'Customs',
              sequenceOrder: 3,
              expectedTime: minutesFromNow(120),
              status: 'PENDING',
              confidenceScore: 60
            },
            {
              stepName: 'Flight',
              sequenceOrder: 4,
              expectedTime: minutesFromNow(240),
              status: 'PENDING',
              confidenceScore: 60
            },
            {
              stepName: 'Arrival',
              sequenceOrder: 5,
              expectedTime: minutesFromNow(420),
              status: 'PENDING',
              confidenceScore: 60
            },
            {
              stepName: 'Delivery',
              sequenceOrder: 6,
              expectedTime: minutesFromNow(600),
              status: 'PENDING',
              confidenceScore: 60
            }
          ]
        }
      },
      include: {
        steps: { orderBy: { sequenceOrder: 'asc' } },
        participants: true
      }
    });

    await prisma.shipment.update({
      where: { id: primaryShipment.id },
      data: { currentStepId: primaryShipment.steps[0].id }
    });

    await prisma.contact.createMany({
      data: [
        {
          shipmentId: primaryShipment.id,
          userId: transporter.id,
          priority: 1,
          trustScore: 76,
          escalationOrder: 1,
          responseTimeAvg: 28
        },
        {
          shipmentId: primaryShipment.id,
          userId: broker.id,
          priority: 2,
          trustScore: 96,
          escalationOrder: 2,
          responseTimeAvg: 7
        },
        {
          shipmentId: primaryShipment.id,
          userId: authority.id,
          priority: 3,
          trustScore: 88,
          escalationOrder: 3,
          responseTimeAvg: 18
        }
      ]
    });

    await prisma.shipmentLog.createMany({
      data: [
        {
          shipmentId: primaryShipment.id,
          performedBy: broker.id,
          performerRole: 'BROKER',
          action: 'SHIPMENT_CREATED',
          newStatus: 'IN_TRANSIT',
          notes: 'Demo shipment created with multi-party participation',
          sourceType: 'USER',
          confidenceScore: 92
        },
        {
          shipmentId: primaryShipment.id,
          shipmentStepId: primaryShipment.steps[0].id,
          performedBy: transporter.id,
          performerRole: 'TRANSPORTER',
          action: 'STEP_UPDATED',
          previousStatus: 'PENDING',
          newStatus: 'IN_PROGRESS',
          notes: 'Vehicle reached pickup gate; loading confirmation pending',
          sourceType: 'USER',
          confidenceScore: 70
        }
      ]
    });
  }

  if (!primaryShipment) {
    throw new Error('Failed to initialize primary demo shipment');
  }

  let confirmationShipment = await prisma.shipment.findUnique({
    where: { referenceNumber: 'FS-DEMO-MUM-SIN-002' },
    include: {
      steps: { orderBy: { sequenceOrder: 'asc' } }
    }
  });

  if (!confirmationShipment) {
    confirmationShipment = await prisma.shipment.create({
      data: {
        referenceNumber: 'FS-DEMO-MUM-SIN-002',
        origin: 'Nhava Sheva Port, Mumbai',
        destination: 'Jurong Port, Singapore',
        transportType: 'SEA',
        priorityLevel: 'HIGH',
        createdBy: broker.id,
        currentStatus: 'NEEDS_CONFIRMATION',
        participants: {
          create: [
            {
              userId: broker.id,
              participantRole: 'BROKER',
              permissions: permissionTemplates.BROKER,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 95,
              responseRate: 100,
              lastActivityAt: minutesFromNow(-22)
            },
            {
              userId: client.id,
              participantRole: 'CLIENT',
              permissions: permissionTemplates.CLIENT,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 85,
              responseRate: 96,
              lastActivityAt: minutesFromNow(-30)
            },
            {
              userId: transporter.id,
              participantRole: 'TRANSPORTER',
              permissions: permissionTemplates.TRANSPORTER,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 78,
              responseRate: 69,
              lastActivityAt: minutesFromNow(-85)
            },
            {
              userId: authority.id,
              participantRole: 'AUTHORITY',
              permissions: permissionTemplates.AUTHORITY,
              inviteStatus: 'JOINED',
              joinedAt: new Date(),
              reliabilityScore: 89,
              responseRate: 94,
              lastActivityAt: minutesFromNow(-12)
            }
          ]
        },
        steps: {
          create: [
            {
              stepName: 'Export Documentation',
              sequenceOrder: 1,
              expectedTime: minutesFromNow(-300),
              actualTime: minutesFromNow(-288),
              status: 'COMPLETED',
              updateSource: 'BROKER',
              updatedBy: broker.id,
              confidenceScore: 92,
              escalationStatus: 'NONE'
            },
            {
              stepName: 'Port Gate In',
              sequenceOrder: 2,
              expectedTime: minutesFromNow(-120),
              status: 'NEEDS_CONFIRMATION',
              updateSource: 'TRANSPORTER',
              updatedBy: transporter.id,
              confidenceScore: 63,
              escalationStatus: 'NEEDS_CONFIRMATION'
            },
            {
              stepName: 'Customs Clearance',
              sequenceOrder: 3,
              expectedTime: minutesFromNow(90),
              status: 'PENDING',
              confidenceScore: 66
            },
            {
              stepName: 'Vessel Departure',
              sequenceOrder: 4,
              expectedTime: minutesFromNow(240),
              status: 'PENDING',
              confidenceScore: 66
            }
          ]
        }
      },
      include: {
        steps: { orderBy: { sequenceOrder: 'asc' } }
      }
    });

    await prisma.shipment.update({
      where: { id: confirmationShipment.id },
      data: { currentStepId: confirmationShipment.steps[1].id }
    });

    await prisma.contact.createMany({
      data: [
        {
          shipmentId: confirmationShipment.id,
          userId: broker.id,
          priority: 1,
          trustScore: 95,
          escalationOrder: 1,
          responseTimeAvg: 8
        },
        {
          shipmentId: confirmationShipment.id,
          userId: authority.id,
          priority: 2,
          trustScore: 89,
          escalationOrder: 2,
          responseTimeAvg: 14
        },
        {
          shipmentId: confirmationShipment.id,
          userId: transporter.id,
          priority: 3,
          trustScore: 78,
          escalationOrder: 3,
          responseTimeAvg: 31
        }
      ]
    });

    await prisma.shipmentLog.createMany({
      data: [
        {
          shipmentId: confirmationShipment.id,
          performedBy: broker.id,
          performerRole: 'BROKER',
          action: 'SHIPMENT_CREATED',
          newStatus: 'NEEDS_CONFIRMATION',
          notes: 'High-priority sea leg created for showcase',
          sourceType: 'USER',
          confidenceScore: 93
        },
        {
          shipmentId: confirmationShipment.id,
          shipmentStepId: confirmationShipment.steps[0].id,
          performedBy: broker.id,
          performerRole: 'BROKER',
          action: 'STEP_UPDATED',
          previousStatus: 'IN_PROGRESS',
          newStatus: 'COMPLETED',
          notes: 'Export docs verified and uploaded',
          sourceType: 'USER',
          confidenceScore: 90
        },
        {
          shipmentId: confirmationShipment.id,
          shipmentStepId: confirmationShipment.steps[1].id,
          performedBy: transporter.id,
          performerRole: 'TRANSPORTER',
          action: 'FIRST_CONFIRMATION',
          previousStatus: 'IN_PROGRESS',
          newStatus: 'NEEDS_CONFIRMATION',
          notes: 'Gate-in photo uploaded, waiting broker confirmation',
          sourceType: 'USER',
          confidenceScore: 63,
          isFirstConfirmation: true
        }
      ]
    });
  }

  if (!confirmationShipment) {
    throw new Error('Failed to initialize confirmation demo shipment');
  }

  const completedShipment = await prisma.shipment.create({
    data: {
      referenceNumber: 'FS-DEMO-BLR-PNQ-003',
      origin: 'Bengaluru Hub',
      destination: 'Pune Distribution Center',
      transportType: 'ROAD',
      priorityLevel: 'MEDIUM',
      createdBy: broker.id,
      currentStatus: 'COMPLETED',
      participants: {
        create: [
          {
            userId: broker.id,
            participantRole: 'BROKER',
            permissions: permissionTemplates.BROKER,
            inviteStatus: 'JOINED',
            joinedAt: new Date(),
            reliabilityScore: 97,
            responseRate: 100,
            lastActivityAt: minutesFromNow(-50)
          },
          {
            userId: client.id,
            participantRole: 'CLIENT',
            permissions: permissionTemplates.CLIENT,
            inviteStatus: 'JOINED',
            joinedAt: new Date(),
            reliabilityScore: 90,
            responseRate: 99,
            lastActivityAt: minutesFromNow(-45)
          },
          {
            userId: transporter.id,
            participantRole: 'TRANSPORTER',
            permissions: permissionTemplates.TRANSPORTER,
            inviteStatus: 'JOINED',
            joinedAt: new Date(),
            reliabilityScore: 92,
            responseRate: 98,
            lastActivityAt: minutesFromNow(-40)
          }
        ]
      },
      steps: {
        create: [
          {
            stepName: 'Pickup Scan',
            sequenceOrder: 1,
            expectedTime: minutesFromNow(-620),
            actualTime: minutesFromNow(-610),
            status: 'COMPLETED',
            updateSource: 'TRANSPORTER',
            updatedBy: transporter.id,
            confidenceScore: 94,
            escalationStatus: 'NONE'
          },
          {
            stepName: 'Cross Dock Transfer',
            sequenceOrder: 2,
            expectedTime: minutesFromNow(-420),
            actualTime: minutesFromNow(-410),
            status: 'COMPLETED',
            updateSource: 'TRANSPORTER',
            updatedBy: transporter.id,
            confidenceScore: 92,
            escalationStatus: 'NONE'
          },
          {
            stepName: 'Delivered',
            sequenceOrder: 3,
            expectedTime: minutesFromNow(-180),
            actualTime: minutesFromNow(-170),
            status: 'COMPLETED',
            updateSource: 'API',
            updatedBy: client.id,
            confidenceScore: 95,
            escalationStatus: 'RESOLVED'
          }
        ]
      }
    },
    include: {
      steps: { orderBy: { sequenceOrder: 'asc' } }
    }
  });

  await prisma.shipment.update({
    where: { id: completedShipment.id },
    data: { currentStepId: completedShipment.steps[2].id }
  });

  await prisma.contact.createMany({
    data: [
      {
        shipmentId: completedShipment.id,
        userId: transporter.id,
        priority: 1,
        trustScore: 92,
        escalationOrder: 1,
        responseTimeAvg: 11
      },
      {
        shipmentId: completedShipment.id,
        userId: client.id,
        priority: 2,
        trustScore: 90,
        escalationOrder: 2,
        responseTimeAvg: 9
      }
    ]
  });

  await prisma.shipmentLog.createMany({
    data: [
      {
        shipmentId: completedShipment.id,
        performedBy: broker.id,
        performerRole: 'BROKER',
        action: 'SHIPMENT_CREATED',
        newStatus: 'IN_TRANSIT',
        notes: 'Regional movement initiated',
        sourceType: 'USER',
        confidenceScore: 93
      },
      {
        shipmentId: completedShipment.id,
        shipmentStepId: completedShipment.steps[2].id,
        performedBy: client.id,
        performerRole: 'CLIENT',
        action: 'STATUS_OVERRIDE',
        previousStatus: 'IN_TRANSIT',
        newStatus: 'COMPLETED',
        notes: 'Consignment received in full at destination',
        sourceType: 'USER',
        confidenceScore: 97
      }
    ]
  });

  logger.info('Seed complete');
  logger.info('Login password for all demo users: Password123!');
  logger.info(
    {
      shipmentReferences: [
        primaryShipment.referenceNumber,
        confirmationShipment.referenceNumber,
        completedShipment.referenceNumber
      ]
    },
    'Demo shipments created'
  );
  logger.info({ brokerEmail: broker.email }, 'Seeded broker account');
  logger.info({ clientEmail: client.email }, 'Seeded client account');
  logger.info({ transporterEmail: transporter.email }, 'Seeded transporter account');
  logger.info({ authorityEmail: authority.email }, 'Seeded authority account');
  logger.info(
    {
      inviteToken: primaryShipment.participants.find((p) => p.inviteToken)?.inviteToken
    },
    'Seeded pending transporter invite token'
  );
}

main()
  .catch((error) => {
    logger.error(
      {
        error,
        errorMessage: error instanceof Error ? error.message : String(error),
        errorCode: typeof error === 'object' && error !== null && 'code' in error
          ? (error as { code?: string }).code
          : undefined,
        errorMeta: typeof error === 'object' && error !== null && 'meta' in error
          ? (error as { meta?: unknown }).meta
          : undefined,
      },
      'Seed failed'
    );
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

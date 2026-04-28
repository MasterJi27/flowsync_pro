import express, { Request, Response } from 'express';
import { prisma } from '../../config/prisma';
import { logger } from '../../config/logger';
import { asyncHandler } from '../../shared/asyncHandler';
import { requireAuth } from '../../middleware/auth';
import {
  getDispatchRecommendation,
  estimateDelayImpact,
  getBestContact,
  calculateTransportReadiness
} from '../../services/transport_advisor';

export const transportRoutes = express.Router();

// Middleware
transportRoutes.use(requireAuth);

/**
 * POST /transport/assign
 * Assign a transporter to a shipment
 */
transportRoutes.post(
  '/assign',
  asyncHandler(async (req: Request, res: Response) => {
    const { shipmentId, transporterId, truckId, driverName, driverPhone, dispatchTime } = req.body;

    // Validate input
    if (!shipmentId || !transporterId) {
      return res.status(400).json({
        error: 'shipmentId and transporterId are required'
      });
    }

    // Check if shipment exists
    const shipment = await prisma.shipment.findUnique({
      where: { id: shipmentId }
    });

    if (!shipment) {
      return res.status(404).json({ error: 'Shipment not found' });
    }

    // Check if transporter is valid participant
    const transporter = await prisma.shipmentParticipant.findUnique({
      where: { id: transporterId }
    });

    if (!transporter) {
      return res.status(404).json({ error: 'Transporter not found' });
    }

    // Create or update transport assignment
    const transportAssignment = await (prisma as any).transportAssignment.upsert({
      where: { shipmentId },
      update: {
        transporterId,
        truckId: truckId || undefined,
        driverName: driverName || undefined,
        driverPhone: driverPhone || undefined,
        dispatchTime: dispatchTime ? new Date(dispatchTime) : undefined,
        status: 'ASSIGNED',
        updatedAt: new Date()
      },
      create: {
        shipmentId,
        transporterId,
        truckId,
        driverName,
        driverPhone,
        dispatchTime: dispatchTime ? new Date(dispatchTime) : undefined,
        status: 'ASSIGNED'
      },
      include: {
        transporter: {
          include: { user: true }
        }
      }
    });

    logger.info(
      { shipmentId, transporterId, truckId },
      'Transport assignment created'
    );

    res.status(201).json({
      success: true,
      data: transportAssignment
    });
  })
);

/**
 * GET /transport/:shipmentId
 * Get transport assignment for a shipment
 */
transportRoutes.get(
  '/:shipmentId',
  asyncHandler(async (req: Request, res: Response) => {
    const shipmentId = req.params.shipmentId as string;

    const transportAssignment = await (prisma as any).transportAssignment.findUnique({
      where: { shipmentId },
      include: {
        transporter: {
          include: { user: true }
        }
      }
    });

    if (!transportAssignment) {
      return res.status(404).json({
        error: 'No transport assignment found for this shipment'
      });
    }

    res.json({
      success: true,
      data: transportAssignment
    });
  })
);

/**
 * PATCH /transport/update/:shipmentId
 * Update transport assignment status
 */
transportRoutes.patch(
  '/update/:shipmentId',
  asyncHandler(async (req: Request, res: Response) => {
    const shipmentId = req.params.shipmentId as string;
    const { status, actualArrivalTime, notes } = req.body;

    // Validate status
    const validStatuses = ['ASSIGNED', 'ENROUTE', 'ARRIVED', 'COMPLETED'];
    if (status && !validStatuses.includes(status)) {
      return res.status(400).json({
        error: `Invalid status. Must be one of: ${validStatuses.join(', ')}`
      });
    }

    // Check if assignment exists
    const existingAssignment = await (prisma as any).transportAssignment.findUnique({
      where: { shipmentId }
    });

    if (!existingAssignment) {
      return res.status(404).json({
        error: 'Transport assignment not found'
      });
    }

    // Update assignment
    const updatedAssignment = await (prisma as any).transportAssignment.update({
      where: { shipmentId },
      data: {
        status: status || undefined,
        actualArrivalTime: actualArrivalTime ? new Date(actualArrivalTime) : undefined,
        notes: notes || undefined,
        updatedAt: new Date()
      },
      include: {
        transporter: {
          include: { user: true }
        }
      }
    });

    logger.info(
      { shipmentId, status },
      'Transport assignment updated'
    );

    res.json({
      success: true,
      data: updatedAssignment
    });
  })
);

/**
 * GET /transport/recommendation/:shipmentId
 * Get dispatch recommendation for a shipment
 */
transportRoutes.get(
  '/recommendation/:shipmentId',
  asyncHandler(async (req: Request, res: Response) => {
    const shipmentId = req.params.shipmentId as string;

    // Check if shipment exists
    const shipment = await prisma.shipment.findUnique({
      where: { id: shipmentId }
    });

    if (!shipment) {
      return res.status(404).json({ error: 'Shipment not found' });
    }

    const recommendation = await getDispatchRecommendation(shipmentId);
    res.json({
      success: true,
      data: recommendation
    });
  })
);

/**
 * GET /transport/readiness/:shipmentId
 * Calculate transport readiness score
 */
transportRoutes.get(
  '/readiness/:shipmentId',
  asyncHandler(async (req: Request, res: Response) => {
    const shipmentId = req.params.shipmentId as string;

    const readiness = await calculateTransportReadiness(shipmentId);
    res.json({
      success: true,
      data: readiness
    });
  })
);

/**
 * GET /transport/impact/:shipmentId
 * Estimate delay impact
 */
transportRoutes.get(
  '/impact/:shipmentId',
  asyncHandler(async (req: Request, res: Response) => {
    const shipmentId = req.params.shipmentId as string;

    const impact = await estimateDelayImpact(shipmentId);
    if (!impact) {
      return res.status(404).json({ error: 'Shipment not found' });
    }

    res.json({
      success: true,
      data: impact
    });
  })
);

/**
 * GET /transport/best-contact/:shipmentId
 * Get best contact for shipment
 */
transportRoutes.get(
  '/best-contact/:shipmentId',
  asyncHandler(async (req: Request, res: Response) => {
    const shipmentId = req.params.shipmentId as string;

    const bestContact = await getBestContact(shipmentId);
    if (!bestContact) {
      return res.status(404).json({ error: 'No contacts found for this shipment' });
    }

    res.json({
      success: true,
      data: bestContact
    });
  })
);

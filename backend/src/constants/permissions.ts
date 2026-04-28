import { ParticipantRole } from '@prisma/client';

export const permissionTemplates: Record<ParticipantRole, Record<string, boolean>> = {
  BROKER: {
    'shipment.read': true,
    'shipment.write': true,
    'shipment.delete': true,
    'participants.manage': true,
    'steps.create': true,
    'steps.update': true,
    'steps.override': true,
    'escalation.trigger': true,
    'analytics.read': true,
    'documents.read': true,
    'compliance.confirm': true
  },
  CLIENT: {
    'shipment.read': true,
    'shipment.write': false,
    'shipment.delete': false,
    'participants.manage': false,
    'steps.create': false,
    'steps.update': false,
    'steps.override': false,
    'escalation.trigger': false,
    'analytics.read': false,
    'documents.read': true,
    'compliance.confirm': false
  },
  TRANSPORTER: {
    'shipment.read': true,
    'shipment.write': false,
    'shipment.delete': false,
    'participants.manage': false,
    'steps.create': false,
    'steps.update': true,
    'steps.override': false,
    'escalation.trigger': false,
    'analytics.read': false,
    'documents.read': false,
    'compliance.confirm': false
  },
  AUTHORITY: {
    'shipment.read': true,
    'shipment.write': false,
    'shipment.delete': false,
    'participants.manage': false,
    'steps.create': false,
    'steps.update': true,
    'steps.override': false,
    'escalation.trigger': false,
    'analytics.read': false,
    'documents.read': true,
    'compliance.confirm': true
  }
};

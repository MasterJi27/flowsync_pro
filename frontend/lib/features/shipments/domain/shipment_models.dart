class Shipment {
  const Shipment({
    required this.id,
    required this.referenceNumber,
    required this.origin,
    required this.destination,
    required this.transportType,
    required this.currentStatus,
    required this.priorityLevel,
    required this.createdAt,
    required this.updatedAt,
    this.currentStepId,
    this.steps = const [],
    this.participants = const [],
    this.contacts = const [],
  });

  final String id;
  final String referenceNumber;
  final String origin;
  final String destination;
  final String transportType;
  final String currentStatus;
  final String priorityLevel;
  final String? currentStepId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShipmentStep> steps;
  final List<ShipmentParticipant> participants;
  final List<ShipmentContact> contacts;

  DateTime? get eta {
    for (final step in steps) {
      if (step.status != 'COMPLETED') return step.expectedTime;
    }
    return steps.isEmpty ? null : steps.last.actualTime ?? steps.last.expectedTime;
  }

  ShipmentStep? get currentStep {
    if (currentStepId == null) return steps.isEmpty ? null : steps.first;
    return steps.where((step) => step.id == currentStepId).firstOrNull;
  }

  bool get isDelayed =>
      currentStatus == 'NEEDS_CONFIRMATION' ||
      currentStatus == 'ESCALATED' ||
      currentStatus == 'DELAYED';

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        id: json['id'] as String,
        referenceNumber: json['referenceNumber'] as String,
        origin: json['origin'] as String,
        destination: json['destination'] as String,
        transportType: json['transportType'] as String,
        currentStatus: json['currentStatus'] as String,
        priorityLevel: json['priorityLevel'] as String,
        currentStepId: json['currentStepId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        steps: ((json['steps'] as List?) ?? const [])
            .map((item) => ShipmentStep.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        participants: ((json['participants'] as List?) ?? const [])
            .map((item) => ShipmentParticipant.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        contacts: ((json['contacts'] as List?) ?? const [])
            .map((item) => ShipmentContact.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Shipment copyWith({
    String? currentStatus,
    List<ShipmentStep>? steps,
    List<ShipmentParticipant>? participants,
    List<ShipmentContact>? contacts,
  }) {
    return Shipment(
      id: id,
      referenceNumber: referenceNumber,
      origin: origin,
      destination: destination,
      transportType: transportType,
      currentStatus: currentStatus ?? this.currentStatus,
      priorityLevel: priorityLevel,
      currentStepId: currentStepId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      steps: steps ?? this.steps,
      participants: participants ?? this.participants,
      contacts: contacts ?? this.contacts,
    );
  }
}

class ShipmentStep {
  const ShipmentStep({
    required this.id,
    required this.shipmentId,
    required this.stepName,
    required this.sequenceOrder,
    required this.expectedTime,
    required this.status,
    required this.confidenceScore,
    required this.updateSource,
    required this.escalationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.actualTime,
    this.updatedByName,
  });

  final String id;
  final String shipmentId;
  final String stepName;
  final int sequenceOrder;
  final DateTime expectedTime;
  final DateTime? actualTime;
  final String status;
  final int confidenceScore;
  final String updateSource;
  final String escalationStatus;
  final String? updatedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ShipmentStep.fromJson(Map<String, dynamic> json) => ShipmentStep(
        id: json['id'] as String,
        shipmentId: json['shipmentId'] as String,
        stepName: json['stepName'] as String,
        sequenceOrder: json['sequenceOrder'] as int,
        expectedTime: DateTime.parse(json['expectedTime'] as String),
        actualTime: json['actualTime'] == null ? null : DateTime.parse(json['actualTime'] as String),
        status: json['status'] as String,
        confidenceScore: json['confidenceScore'] as int? ?? 60,
        updateSource: json['updateSource'] as String? ?? 'SYSTEM',
        escalationStatus: json['escalationStatus'] as String? ?? 'NONE',
        updatedByName: (json['updatedByUser'] as Map?)?['name'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  ShipmentStep copyWith({String? status, DateTime? actualTime, int? confidenceScore}) => ShipmentStep(
        id: id,
        shipmentId: shipmentId,
        stepName: stepName,
        sequenceOrder: sequenceOrder,
        expectedTime: expectedTime,
        actualTime: actualTime ?? this.actualTime,
        status: status ?? this.status,
        confidenceScore: confidenceScore ?? this.confidenceScore,
        updateSource: updateSource,
        escalationStatus: escalationStatus,
        updatedByName: updatedByName,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class ShipmentParticipant {
  const ShipmentParticipant({
    required this.id,
    required this.role,
    required this.inviteStatus,
    required this.reliabilityScore,
    required this.responseRate,
    this.name,
    this.phone,
    this.lastActivityAt,
  });

  final String id;
  final String role;
  final String inviteStatus;
  final double reliabilityScore;
  final double responseRate;
  final String? name;
  final String? phone;
  final DateTime? lastActivityAt;

  factory ShipmentParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map?;
    return ShipmentParticipant(
      id: json['id'] as String,
      role: json['participantRole'] as String,
      inviteStatus: json['inviteStatus'] as String,
      reliabilityScore: _toDouble(json['reliabilityScore']),
      responseRate: _toDouble(json['responseRate']),
      name: user?['name'] as String? ?? json['invitePhone'] as String?,
      phone: user?['phone'] as String? ?? json['invitePhone'] as String?,
      lastActivityAt:
          json['lastActivityAt'] == null ? null : DateTime.parse(json['lastActivityAt'] as String),
    );
  }
}

class ShipmentContact {
  const ShipmentContact({
    required this.id,
    required this.priority,
    required this.trustScore,
    required this.escalationOrder,
    required this.responseTimeAvg,
    required this.name,
  });

  final String id;
  final int priority;
  final double trustScore;
  final int escalationOrder;
  final int responseTimeAvg;
  final String name;

  factory ShipmentContact.fromJson(Map<String, dynamic> json) => ShipmentContact(
        id: json['id'] as String,
        priority: json['priority'] as int,
        trustScore: _toDouble(json['trustScore']),
        escalationOrder: json['escalationOrder'] as int,
        responseTimeAvg: json['responseTimeAvg'] as int? ?? 0,
        name: ((json['user'] as Map?)?['name'] as String?) ?? 'Contact',
      );
}

class ShipmentLog {
  const ShipmentLog({
    required this.id,
    required this.action,
    required this.timestamp,
    required this.confidenceScore,
    required this.isFirstConfirmation,
    this.notes,
    this.previousStatus,
    this.newStatus,
    this.performerName,
  });

  final String id;
  final String action;
  final String? previousStatus;
  final String? newStatus;
  final String? notes;
  final DateTime timestamp;
  final bool isFirstConfirmation;
  final int confidenceScore;
  final String? performerName;

  factory ShipmentLog.fromJson(Map<String, dynamic> json) => ShipmentLog(
        id: json['id'] as String,
        action: json['action'] as String,
        previousStatus: json['previousStatus'] as String?,
        newStatus: json['newStatus'] as String?,
        notes: json['notes'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isFirstConfirmation: json['isFirstConfirmation'] as bool? ?? false,
        confidenceScore: json['confidenceScore'] as int? ?? 60,
        performerName: (json['performer'] as Map?)?['name'] as String?,
      );
}

class EscalationAttempt {
  const EscalationAttempt({
    required this.id,
    required this.stepId,
    required this.status,
    required this.sequenceRank,
    this.notifiedAt,
    this.respondedAt,
    this.contactName,
  });

  final String id;
  final String stepId;
  final String status;
  final int sequenceRank;
  final DateTime? notifiedAt;
  final DateTime? respondedAt;
  final String? contactName;

  factory EscalationAttempt.fromJson(Map<String, dynamic> json) => EscalationAttempt(
        id: json['id'] as String,
        stepId: json['shipmentStepId'] as String,
        status: json['status'] as String,
        sequenceRank: json['sequenceRank'] as int,
        notifiedAt: json['notifiedAt'] == null ? null : DateTime.parse(json['notifiedAt'] as String),
        respondedAt: json['respondedAt'] == null ? null : DateTime.parse(json['respondedAt'] as String),
        contactName: ((json['contact'] as Map?)?['user'] as Map?)?['name'] as String? ??
            ((json['participant'] as Map?)?['user'] as Map?)?['name'] as String?,
      );
}

class ShipmentDetailBundle {
  const ShipmentDetailBundle({
    required this.shipment,
    required this.logs,
    required this.escalations,
  });

  final Shipment shipment;
  final List<ShipmentLog> logs;
  final List<EscalationAttempt> escalations;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class DelayAnalytics {
  const DelayAnalytics({
    required this.totalSteps,
    required this.delayedSteps,
    required this.delayPercent,
    required this.averageDelayMinutes,
    required this.needsConfirmation,
  });

  final int totalSteps;
  final int delayedSteps;
  final double delayPercent;
  final int averageDelayMinutes;
  final int needsConfirmation;

  factory DelayAnalytics.fromJson(Map<String, dynamic> json) => DelayAnalytics(
        totalSteps: json['totalSteps'] as int? ?? 0,
        delayedSteps: json['delayedSteps'] as int? ?? 0,
        delayPercent: (json['delayPercent'] as num? ?? 0).toDouble(),
        averageDelayMinutes: json['averageDelayMinutes'] as int? ?? 0,
        needsConfirmation: json['needsConfirmation'] as int? ?? 0,
      );
}

class PerformanceAnalytics {
  const PerformanceAnalytics({
    required this.activeShipments,
    required this.completedShipments,
    required this.completionRate,
    required this.averageConfirmationMinutes,
    required this.escalationFrequency,
  });

  final int activeShipments;
  final int completedShipments;
  final double completionRate;
  final int averageConfirmationMinutes;
  final double escalationFrequency;

  factory PerformanceAnalytics.fromJson(Map<String, dynamic> json) => PerformanceAnalytics(
        activeShipments: json['activeShipments'] as int? ?? 0,
        completedShipments: json['completedShipments'] as int? ?? 0,
        completionRate: (json['completionRate'] as num? ?? 0).toDouble(),
        averageConfirmationMinutes: json['averageConfirmationMinutes'] as int? ?? 0,
        escalationFrequency: (json['escalationFrequency'] as num? ?? 0).toDouble(),
      );
}

class ReliabilityAnalytics {
  const ReliabilityAnalytics({
    required this.averageReliability,
    required this.transporters,
  });

  final int averageReliability;
  final List<TransporterReliability> transporters;

  factory ReliabilityAnalytics.fromJson(Map<String, dynamic> json) => ReliabilityAnalytics(
        averageReliability: json['averageReliability'] as int? ?? 0,
        transporters: ((json['transporters'] as List?) ?? const [])
            .map((item) => TransporterReliability.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class TransporterReliability {
  const TransporterReliability({
    required this.name,
    required this.reliabilityScore,
    required this.responseRate,
    required this.shipmentReference,
  });

  final String name;
  final double reliabilityScore;
  final double responseRate;
  final String shipmentReference;

  factory TransporterReliability.fromJson(Map<String, dynamic> json) => TransporterReliability(
        name: json['name'] as String? ?? 'Transporter',
        reliabilityScore: (json['reliabilityScore'] as num? ?? 0).toDouble(),
        responseRate: (json['responseRate'] as num? ?? 0).toDouble(),
        shipmentReference: json['shipmentReference'] as String? ?? '',
      );
}

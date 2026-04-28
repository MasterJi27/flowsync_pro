/// Real-time transport events integration with Socket.IO
/// Handles updates for transport status, timeline, and map markers
library;

class TransportRealtimeEvents {
  // Event names (synchronized with backend)
  static const String transportAssigned = 'transport:assigned';
  static const String transportStatusChanged = 'transport:status_changed';
  static const String transportLocationUpdated = 'transport:location_updated';
  static const String transportETA = 'transport:eta_updated';
  static const String dispatchRecommendationUpdated =
      'transport:dispatch_recommendation';
  static const String riskAlertTriggered = 'transport:risk_alert';

  /// Models for real-time events

  /// Transport assignment event
  static Map<String, dynamic> createAssignmentEvent({
    required String shipmentId,
    required String transporterId,
    String? driverName,
    String? driverPhone,
    String? truckId,
  }) {
    return {
      'event': transportAssigned,
      'shipmentId': shipmentId,
      'transporterId': transporterId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'truckId': truckId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Transport status change event
  static Map<String, dynamic> createStatusChangeEvent({
    required String shipmentId,
    required String oldStatus,
    required String newStatus,
    DateTime? eventTime,
  }) {
    return {
      'event': transportStatusChanged,
      'shipmentId': shipmentId,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'timestamp':
          eventTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// Location update event
  static Map<String, dynamic> createLocationUpdateEvent({
    required String shipmentId,
    required double latitude,
    required double longitude,
    String? address,
    DateTime? timestamp,
  }) {
    return {
      'event': transportLocationUpdated,
      'shipmentId': shipmentId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp':
          timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  /// ETA update event
  static Map<String, dynamic> createETAUpdateEvent({
    required String shipmentId,
    required DateTime estimatedArrival,
    int? delayMinutes,
  }) {
    return {
      'event': transportETA,
      'shipmentId': shipmentId,
      'estimatedArrival': estimatedArrival.toIso8601String(),
      'delayMinutes': delayMinutes,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispatch recommendation update event
  static Map<String, dynamic> createDispatchRecommendationEvent({
    required String shipmentId,
    required String riskLevel,
    required String message,
    int? recommendedDelayMinutes,
  }) {
    return {
      'event': dispatchRecommendationUpdated,
      'shipmentId': shipmentId,
      'riskLevel': riskLevel,
      'message': message,
      'recommendedDelayMinutes': recommendedDelayMinutes,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Risk alert event
  static Map<String, dynamic> createRiskAlertEvent({
    required String shipmentId,
    required String
        alertType, // 'no_update', 'delay_expected', 'escalation_needed'
    required int severity, // 1-5
    String? message,
  }) {
    return {
      'event': riskAlertTriggered,
      'shipmentId': shipmentId,
      'alertType': alertType,
      'severity': severity,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Socket.IO Handler Integration
/// Add this to your existing Socket service
abstract class TransportSocketHandler {
  /// Register all transport event listeners
  static void registerTransportListeners(dynamic socketIO) {
    // Listen for transport assignments
    socketIO.on(
      TransportRealtimeEvents.transportAssigned,
      (data) => _handleTransportAssigned(data),
    );

    // Listen for status changes
    socketIO.on(
      TransportRealtimeEvents.transportStatusChanged,
      (data) => _handleStatusChange(data),
    );

    // Listen for location updates
    socketIO.on(
      TransportRealtimeEvents.transportLocationUpdated,
      (data) => _handleLocationUpdate(data),
    );

    // Listen for ETA updates
    socketIO.on(
      TransportRealtimeEvents.transportETA,
      (data) => _handleETAUpdate(data),
    );

    // Listen for dispatch recommendations
    socketIO.on(
      TransportRealtimeEvents.dispatchRecommendationUpdated,
      (data) => _handleDispatchRecommendation(data),
    );

    // Listen for risk alerts
    socketIO.on(
      TransportRealtimeEvents.riskAlertTriggered,
      (data) => _handleRiskAlert(data),
    );
  }

  static void _handleTransportAssigned(Map<String, dynamic> data) {
    // Update local state - e.g., Riverpod notifier
    // Example:
    // final shipmentId = data['shipmentId'];
    // ref.read(shipmentProvider(shipmentId).notifier).updateTransport(data);
    print('Transport assigned: ${data['shipmentId']}');
  }

  static void _handleStatusChange(Map<String, dynamic> data) {
    // Update transport status in UI
    print(
        'Transport status changed: ${data['shipmentId']} - ${data['newStatus']}');
  }

  static void _handleLocationUpdate(Map<String, dynamic> data) {
    // Update map markers in real-time
    print(
        'Location update: ${data['shipmentId']} - (${data['latitude']}, ${data['longitude']})');
  }

  static void _handleETAUpdate(Map<String, dynamic> data) {
    // Update ETA in transport card
    print('ETA updated: ${data['shipmentId']} - ${data['estimatedArrival']}');
  }

  static void _handleDispatchRecommendation(Map<String, dynamic> data) {
    // Update dispatch advisor card
    print(
        'Dispatch recommendation: ${data['shipmentId']} - ${data['riskLevel']}');
  }

  static void _handleRiskAlert(Map<String, dynamic> data) {
    // Show risk alert in UI
    print('Risk alert: ${data['shipmentId']} - ${data['alertType']}');
  }

  /// Unregister listeners when needed (cleanup)
  static void unregisterTransportListeners(dynamic socketIO) {
    socketIO.off(TransportRealtimeEvents.transportAssigned);
    socketIO.off(TransportRealtimeEvents.transportStatusChanged);
    socketIO.off(TransportRealtimeEvents.transportLocationUpdated);
    socketIO.off(TransportRealtimeEvents.transportETA);
    socketIO.off(TransportRealtimeEvents.dispatchRecommendationUpdated);
    socketIO.off(TransportRealtimeEvents.riskAlertTriggered);
  }
}

/// Example integration with existing Socket service:
/// 
/// ```dart
/// class SocketService extends ChangeNotifier {
///   late IO.Socket socket;
///   
///   void connect() {
///     socket = IO.io('http://your-api.com', ...);
///     
///     socket.onConnect((_) {
///       // Register transport listeners
///       TransportSocketHandler.registerTransportListeners(socket);
///     });
///   }
///   
///   void disconnect() {
///     TransportSocketHandler.unregisterTransportListeners(socket);
///     socket.disconnect();
///   }
/// }
/// ```

/// Riverpod Notifier Example for transport state management
/// 
/// ```dart
/// @riverpod
/// class ShipmentTransportNotifier extends _$ShipmentTransportNotifier {
///   @override
///   FutureOr<TransportAssignmentData?> build(String shipmentId) async {
///     // Initial fetch from API
///     return await fetchTransportAssignment(shipmentId);
///   }
///   
///   void updateFromRealtime(Map<String, dynamic> data) {
///     state = AsyncData(TransportAssignmentData.fromJson(data));
///   }
///   
///   void updateStatus(String newStatus) {
///     state.whenData((transport) {
///       final updated = transport?.copyWith(status: newStatus);
///       state = AsyncData(updated);
///     });
///   }
/// }
/// ```

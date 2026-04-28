import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../domain/shipment_models.dart';

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepository(ref.watch(dioProvider), ref.watch(localStoreProvider));
});

class ShipmentRepository {
  const ShipmentRepository(this._dio, this._store);

  final Dio _dio;
  final LocalStore _store;

  Future<List<Shipment>> list({
    String? search,
    String? status,
    String? priority,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/shipments',
        queryParameters: {
          'limit': 50,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (priority != null && priority.isNotEmpty) 'priority': priority,
        },
      );
      final items = (response.data!['items'] as List).cast<Map>();
      final jsonItems = items.map((item) => Map<String, dynamic>.from(item)).toList();
      await _store.cacheShipments(jsonItems);
      return jsonItems.map(Shipment.fromJson).toList();
    } on DioException {
      final cached = _store.cachedShipments();
      if (cached.isNotEmpty) return cached.map(Shipment.fromJson).toList();
      rethrow;
    }
  }

  Future<ShipmentDetailBundle> detail(String id) async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>('/shipments/$id'),
        _dio.get<List<dynamic>>('/logs/$id'),
        _dio.get<List<dynamic>>('/escalations/$id'),
      ]);
      final shipmentJson = Map<String, dynamic>.from(responses[0].data! as Map);
      await _store.cacheShipment(id, shipmentJson);
      return ShipmentDetailBundle(
        shipment: Shipment.fromJson(shipmentJson),
        logs: (responses[1].data as List)
            .map((item) => ShipmentLog.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        escalations: (responses[2].data as List)
            .map((item) => EscalationAttempt.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
    } on DioException {
      final cached = _store.cachedShipment(id);
      if (cached != null) {
        return ShipmentDetailBundle(
          shipment: Shipment.fromJson(cached),
          logs: const [],
          escalations: const [],
        );
      }
      rethrow;
    }
  }

  Future<ShipmentStep> updateStep(
    String stepId, {
    required String status,
    String? notes,
    int? confidenceScore,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/steps/$stepId',
      data: {
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (confidenceScore != null) 'confidenceScore': confidenceScore,
      },
    );
    return ShipmentStep.fromJson(response.data!);
  }

  Future<void> triggerEscalation({
    required String shipmentId,
    required String stepId,
    String? reason,
  }) async {
    await _dio.post<void>(
      '/escalations/trigger',
      data: {
        'shipmentId': shipmentId,
        'stepId': stepId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  Future<String> inviteTransporter(String shipmentId, String phone) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/shipments/$shipmentId/invite-transporter',
      data: {'phone': phone},
    );
    return (response.data!['invite'] as Map)['token'] as String;
  }

  Future<void> queueStepUpdate(String stepId, Map<String, dynamic> payload) {
    return _store.enqueue('step:$stepId:${DateTime.now().microsecondsSinceEpoch}', {
      'method': 'PATCH',
      'path': '/steps/$stepId',
      'payload': payload,
    });
  }
}

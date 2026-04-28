import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/config/app_config.dart';
import '../../../core/realtime/realtime_service.dart';
import '../data/shipment_repository.dart';
import '../domain/shipment_models.dart';

final shipmentListControllerProvider =
    StateNotifierProvider.autoDispose<
      ShipmentListController,
      AsyncValue<List<Shipment>>
    >((ref) {
      return ShipmentListController(ref);
    });

final shipmentDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<ShipmentDetailController, AsyncValue<ShipmentDetailBundle>, String>(
      (ref, shipmentId) {
        return ShipmentDetailController(ref, shipmentId);
      },
    );

class ShipmentListController extends StateNotifier<AsyncValue<List<Shipment>>> {
  ShipmentListController(this._ref) : super(const AsyncLoading()) {
    _events = _ref.read(realtimeServiceProvider).events.listen((event) {
      if (event.name.startsWith('shipment:') ||
          event.name.startsWith('step:') ||
          event.name.startsWith('participant:') ||
          event.name.startsWith('escalation:')) {
        load(silent: true);
      }
    });
    _poll = Timer.periodic(AppConfig.pollInterval, (_) => load(silent: true));
    load();
  }

  final Ref _ref;
  late final StreamSubscription _events;
  Timer? _poll;
  String _search = '';
  String? _status;

  Future<void> load({bool silent = false}) async {
    if (!silent) state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _ref
          .read(shipmentRepositoryProvider)
          .list(search: _search, status: _status),
    );
  }

  Future<void> search(String value) async {
    _search = value;
    await load();
  }

  Future<void> filterStatus(String? status) async {
    _status = status;
    await load();
  }

  @override
  void dispose() {
    _events.cancel();
    _poll?.cancel();
    super.dispose();
  }
}

class ShipmentDetailController
    extends StateNotifier<AsyncValue<ShipmentDetailBundle>> {
  ShipmentDetailController(this._ref, this.shipmentId)
    : super(const AsyncLoading()) {
    _ref.read(realtimeServiceProvider).joinShipment(shipmentId);
    _events = _ref.read(realtimeServiceProvider).events.listen((event) {
      final payload = event.payload;
      final payloadShipmentId = payload is Map
          ? payload['shipmentId']?.toString()
          : null;
      if (payloadShipmentId == shipmentId) {
        load(silent: true);
      }
    });
    _poll = Timer.periodic(AppConfig.pollInterval, (_) => load(silent: true));
    load();
  }

  final Ref _ref;
  final String shipmentId;
  late final StreamSubscription _events;
  Timer? _poll;

  Future<void> load({bool silent = false}) async {
    if (!silent) state = const AsyncLoading();
    final repo = _ref.read(shipmentRepositoryProvider);
    final next = await AsyncValue.guard(() => repo.detail(shipmentId));
    if (mounted) state = next;
  }

  Future<void> confirmStep(
    ShipmentStep step, {
    String status = 'COMPLETED',
    String? notes,
  }) async {
    final current = state.value;
    if (current != null) {
      final optimisticSteps = current.shipment.steps
          .map(
            (item) => item.id == step.id
                ? item.copyWith(
                    status: status,
                    actualTime: DateTime.now(),
                    confidenceScore: 78,
                  )
                : item,
          )
          .toList();
      state = AsyncData(
        ShipmentDetailBundle(
          shipment: current.shipment.copyWith(
            currentStatus: status == 'COMPLETED'
                ? 'IN_TRANSIT'
                : current.shipment.currentStatus,
            steps: optimisticSteps,
          ),
          logs: current.logs,
          escalations: current.escalations,
        ),
      );
    }

    final repo = _ref.read(shipmentRepositoryProvider);
    try {
      await repo.updateStep(
        step.id,
        status: status,
        notes: notes,
        confidenceScore: 78,
      );
      await load(silent: true);
    } catch (_) {
      await repo.queueStepUpdate(step.id, {
        'status': status,
        if (notes != null) 'notes': notes,
        'confidenceScore': 78,
      });
      rethrow;
    }
  }

  Future<void> triggerEscalation(ShipmentStep step) async {
    await _ref
        .read(shipmentRepositoryProvider)
        .triggerEscalation(
          shipmentId: shipmentId,
          stepId: step.id,
          reason: 'Manual escalation requested from Android action panel',
        );
    await load(silent: true);
  }

  Future<String> inviteTransporter(String phone) async {
    final token = await _ref
        .read(shipmentRepositoryProvider)
        .inviteTransporter(shipmentId, phone);
    await load(silent: true);
    return token;
  }

  @override
  void dispose() {
    _events.cancel();
    _poll?.cancel();
    super.dispose();
  }
}

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore.instance);

class LocalStore {
  LocalStore._();

  static final instance = LocalStore._();

  static const _sessionBoxName = 'session';
  static const _cacheBoxName = 'cache';
  static const _queueBoxName = 'outbox';

  late Box _session;
  late Box _cache;
  late Box _queue;

  Future<void> init() async {
    _session = await Hive.openBox(_sessionBoxName);
    _cache = await Hive.openBox(_cacheBoxName);
    _queue = await Hive.openBox(_queueBoxName);
  }

  String? get token => _session.get('token') as String?;
  String? get activeRole => _session.get('activeRole') as String?;
  Map<String, dynamic>? get userJson {
    final raw = _session.get('user') as String?;
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveToken(String token) => _session.put('token', token);
  Future<void> saveUser(Map<String, dynamic> user) => _session.put('user', jsonEncode(user));
  Future<void> saveActiveRole(String role) => _session.put('activeRole', role);

  Future<void> clearSession() async {
    await _session.clear();
  }

  Future<void> cacheShipments(List<Map<String, dynamic>> shipments) =>
      _cache.put('shipments', jsonEncode(shipments));

  List<Map<String, dynamic>> cachedShipments() {
    final raw = _cache.get('shipments') as String?;
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> cacheShipment(String id, Map<String, dynamic> shipment) =>
      _cache.put('shipment:$id', jsonEncode(shipment));

  Map<String, dynamic>? cachedShipment(String id) {
    final raw = _cache.get('shipment:$id') as String?;
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> enqueue(String key, Map<String, dynamic> payload) =>
      _queue.put(key, jsonEncode(payload));

  Future<void> removeQueued(String key) => _queue.delete(key);

  Map<String, Map<String, dynamic>> queuedRequests() {
    return {
      for (final key in _queue.keys)
        key.toString(): Map<String, dynamic>.from(jsonDecode(_queue.get(key) as String) as Map)
    };
  }
}

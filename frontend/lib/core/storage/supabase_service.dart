import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return const SupabaseService();
});

class SupabaseService {
  const SupabaseService();

  bool get isConfigured => AppConfig.isSupabaseConfigured;

  SupabaseClient? get _client {
    if (!isConfigured) {
      return null;
    }

    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertUserProfile({
    required String firebaseUid,
    required String email,
    String? name,
    String? phone,
    String? globalRole,
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }

    final payload = <String, dynamic>{
      'firebase_uid': firebaseUid,
      'email': email,
      'name': name,
      'phone': phone,
      'global_role': globalRole,
      'last_login_at': DateTime.now().toUtc().toIso8601String(),
      'last_active_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await client
          .from('user_profiles')
          .upsert(payload, onConflict: 'firebase_uid');
    } catch (_) {
      // Auth should not fail because of analytics/storage side effects.
    }
  }

  Future<void> insertLoginActivity({
    required String firebaseUid,
    required String identifier,
    required String loginMethod,
    required bool success,
    String? errorMessage,
    String? backendUserId,
    String? activeRole,
    String? deviceInfo,
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }

    try {
      await client.from('login_activity').insert({
        'firebase_uid': firebaseUid,
        'identifier': identifier,
        'login_method': loginMethod,
        'success': success,
        'error_message': errorMessage,
        'backend_user_id': backendUserId,
        'active_role': activeRole,
        'device_info': deviceInfo,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Auth should not fail because of analytics/storage side effects.
    }
  }

  Future<void> upsertSession({
    required String firebaseUid,
    required bool isActive,
    String? backendUserId,
    String? activeRole,
    String? tokenPreview,
    String? deviceInfo,
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await client.from('user_sessions').insert({
        'firebase_uid': firebaseUid,
        'backend_user_id': backendUserId,
        'active_role': activeRole,
        'token_preview': tokenPreview,
        'device_info': deviceInfo,
        'is_active': isActive,
        'last_active_at': now,
        'ended_at': isActive ? null : now,
      });
    } catch (_) {
      // Auth should not fail because of analytics/storage side effects.
    }
  }

  Future<void> markSessionsInactive(String firebaseUid) async {
    final client = _client;
    if (client == null) {
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await client
          .from('user_sessions')
          .update({'is_active': false, 'ended_at': now, 'last_active_at': now})
          .eq('firebase_uid', firebaseUid)
          .eq('is_active', true);
    } catch (_) {
      // Auth should not fail because of analytics/storage side effects.
    }
  }
}

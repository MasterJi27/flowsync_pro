import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/supabase_service.dart';
import '../domain/app_user.dart';

final loginActivityRepositoryProvider = Provider<LoginActivityRepository>((
  ref,
) {
  return LoginActivityRepository(ref.watch(supabaseServiceProvider));
});

class LoginActivityRepository {
  const LoginActivityRepository(this._supabase);

  final SupabaseService _supabase;

  Future<void> syncProfile({
    required String firebaseUid,
    required String email,
    String? name,
    String? phone,
    String? role,
  }) {
    return _supabase.upsertUserProfile(
      firebaseUid: firebaseUid,
      email: email,
      name: name,
      phone: phone,
      globalRole: role,
    );
  }

  Future<void> logLogin({
    required String firebaseUid,
    required String identifier,
    required String method,
    required bool success,
    String? errorMessage,
    AppUser? user,
  }) {
    return _supabase.insertLoginActivity(
      firebaseUid: firebaseUid,
      identifier: identifier,
      loginMethod: method,
      success: success,
      errorMessage: errorMessage,
      backendUserId: user?.id,
      activeRole: user?.globalRole,
      deviceInfo: _deviceInfo(),
    );
  }

  Future<void> markSessionActive({
    required String firebaseUid,
    AppUser? user,
    String? token,
  }) {
    return _supabase.upsertSession(
      firebaseUid: firebaseUid,
      isActive: true,
      backendUserId: user?.id,
      activeRole: user?.globalRole,
      tokenPreview: _tokenPreview(token),
      deviceInfo: _deviceInfo(),
    );
  }

  Future<void> markSessionInactive(String firebaseUid) {
    return _supabase.markSessionsInactive(firebaseUid);
  }

  String _deviceInfo() {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name;
  }

  String? _tokenPreview(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    final safeLength = token.length < 12 ? token.length : 12;
    return token.substring(0, safeLength);
  }
}

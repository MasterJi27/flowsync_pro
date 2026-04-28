import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthResult {
  const AuthResult({
    required this.token,
    required this.user,
    this.participantRole,
  });

  final String token;
  final AppUser user;
  final String? participantRole;
}

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResult> login(String emailOrPhone, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'emailOrPhone': emailOrPhone.trim().toLowerCase(),
        'password': password,
      },
    );
    final data = response.data!;
    return AuthResult(
      token: data['token'] as String,
      user: AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<AuthResult> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? inviteToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        if (inviteToken != null && inviteToken.trim().isNotEmpty)
          'inviteToken': inviteToken.trim(),
      },
    );
    final data = response.data!;
    return AuthResult(
      token: data['token'] as String,
      user: AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<AuthResult> inviteAccess(String token, {String? phone}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/invite-access',
      data: {
        'token': token,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    final data = response.data!;
    final participant = Map<String, dynamic>.from(data['participant'] as Map);
    return AuthResult(
      token: data['token'] as String,
      participantRole:
          participant['participantRole'] as String? ?? 'TRANSPORTER',
      user: AppUser(
        id: participant['id'] as String,
        name: participant['invitePhone'] as String? ?? 'Invited transporter',
        phone: participant['invitePhone'] as String? ?? '',
        email: '',
        globalRole: participant['participantRole'] as String? ?? 'TRANSPORTER',
      ),
    );
  }

  Future<AuthResult> firebaseLogin({
    required String idToken,
    String? email,
    String? phone,
    String? name,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/firebase-login',
      data: {
        'idToken': idToken,
        if (email != null && email.trim().isNotEmpty)
          'email': email.trim().toLowerCase(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );

    final data = response.data!;
    return AuthResult(
      token: data['token'] as String,
      user: AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<AppUser?> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data!;
      final userJson = Map<String, dynamic>.from(data['user'] as Map);
      return AppUser.fromJson(userJson);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // ignore
    }
  }
}

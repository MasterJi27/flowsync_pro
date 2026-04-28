import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Needed for GoogleSignInException

import '../../../core/auth/firebase_auth_service.dart';
import '../../../core/realtime/realtime_service.dart';
import '../../../core/storage/local_store.dart';
import '../data/auth_repository.dart';
import '../data/login_activity_repository.dart';
import '../domain/app_user.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.watch(authRepositoryProvider),
      ref.watch(localStoreProvider),
      ref.watch(realtimeServiceProvider),
      ref.watch(firebaseAuthServiceProvider),
      ref.watch(loginActivityRepositoryProvider),
    );
  },
);

class AuthState {
  const AuthState({
    required this.isBootstrapping,
    required this.isLoading,
    this.token,
    this.user,
    this.activeRole,
    this.error,
  });

  const AuthState.initial()
      : isBootstrapping = true,
        isLoading = false,
        token = null,
        user = null,
        activeRole = null,
        error = null;

  final bool isBootstrapping;
  final bool isLoading;
  final String? token;
  final AppUser? user;
  final String? activeRole;
  final String? error;

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    bool? isBootstrapping,
    bool? isLoading,
    String? token,
    AppUser? user,
    String? activeRole,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      user: user ?? this.user,
      activeRole: activeRole ?? this.activeRole,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(
    this._repo,
    this._store,
    this._realtime,
    this._firebase,
    this._activity,
  ) : super(const AuthState.initial()) {
    _restore();
  }

  final AuthRepository _repo;
  final LocalStore _store;
  final RealtimeService _realtime;
  final FirebaseAuthService _firebase;
  final LoginActivityRepository _activity;

  Future<void> _restore() async {
    final token = _store.token;
    final userJson = _store.userJson;
    if (token == null || userJson == null) {
      state = state.copyWith(
        isBootstrapping: false,
        token: null,
        user: null,
        activeRole: null,
      );
      return;
    }
    if (token.startsWith('offline-demo-')) {
      await _store.clearSession();
      state = state.copyWith(
        isBootstrapping: false,
        token: null,
        user: null,
        activeRole: null,
      );
      return;
    }

    // Try to refresh user data from server
    try {
      final freshUser = await _repo.getCurrentUser();
      if (freshUser != null) {
        await _store.saveUser(freshUser.toJson());
        final user = freshUser;
        final role = _store.activeRole ?? user.globalRole;
        _realtime.connect(token);
        await _trackActiveSession(user, token: token);
        state = AuthState(
          isBootstrapping: false,
          isLoading: false,
          token: token,
          user: user,
          activeRole: role,
        );
        return;
      }
    } catch (_) {
      // Fall back to cached user
    }

    final user = AppUser.fromJson(userJson);
    final role = _store.activeRole ?? user.globalRole;
    _realtime.connect(token);
    await _trackActiveSession(user, token: token);
    state = AuthState(
      isBootstrapping: false,
      isLoading: false,
      token: token,
      user: user,
      activeRole: role,
    );
  }

  Future<void> login(String emailOrPhone, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final identifier = emailOrPhone.trim().toLowerCase();
    String? firebaseUid;

    if (_looksLikeEmail(identifier)) {
      try {
        final credential = await _firebase.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );
        firebaseUid = credential.user?.uid;
      } catch (_) {
        // Keep backend auth available while Firebase is being rolled out.
      }
    }

    try {
      final result = await _repo.login(emailOrPhone, password);
      await _persist(result);

      final identity = _activityIdentity(
        firebaseUid: firebaseUid,
        backendUserId: result.user.id,
      );

      await _activity.syncProfile(
        firebaseUid: identity,
        email: _profileEmail(identifier, result.user.email),
        name: result.user.name,
        phone: result.user.phone,
        role: result.user.globalRole,
      );
      await _activity.logLogin(
        firebaseUid: identity,
        identifier: identifier,
        method: firebaseUid == null
            ? 'backend_password'
            : 'firebase_email_password',
        success: true,
        user: result.user,
      );
      await _activity.markSessionActive(
        firebaseUid: identity,
        user: result.user,
        token: result.token,
      );
    } catch (error) {
      await _activity.logLogin(
        firebaseUid: _activityIdentity(firebaseUid: firebaseUid),
        identifier: identifier,
        method: firebaseUid == null
            ? 'backend_password'
            : 'firebase_email_password',
        success: false,
        errorMessage: _message(error),
      );
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final normalizedEmail = email.trim().toLowerCase();
    String? firebaseUid;

    if (_looksLikeEmail(normalizedEmail)) {
      try {
        final credential = await _firebase.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
          displayName: name,
        );
        firebaseUid = credential.user?.uid;
      } catch (_) {
        // If account already exists in Firebase, use backend registration result.
      }
    }

    try {
      final result = await _repo.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      await _persist(result);

      final identity = _activityIdentity(
        firebaseUid: firebaseUid,
        backendUserId: result.user.id,
      );

      await _activity.syncProfile(
        firebaseUid: identity,
        email: _profileEmail(normalizedEmail, result.user.email),
        name: result.user.name,
        phone: result.user.phone,
        role: result.user.globalRole,
      );
      await _activity.logLogin(
        firebaseUid: identity,
        identifier: normalizedEmail,
        method: 'register_email_password',
        success: true,
        user: result.user,
      );
      await _activity.markSessionActive(
        firebaseUid: identity,
        user: result.user,
        token: result.token,
      );
    } catch (error) {
      await _activity.logLogin(
        firebaseUid: _activityIdentity(firebaseUid: firebaseUid),
        identifier: normalizedEmail,
        method: 'register_email_password',
        success: false,
        errorMessage: _message(error),
      );
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<void> inviteAccess(String token, {String? phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.inviteAccess(token, phone: phone);
      await _persist(result);

      final identity = _activityIdentity(backendUserId: result.user.id);
      await _activity.logLogin(
        firebaseUid: identity,
        identifier: phone?.trim() ?? 'invite_token',
        method: 'invite_access',
        success: true,
        user: result.user,
      );
      await _activity.markSessionActive(
        firebaseUid: identity,
        user: result.user,
        token: result.token,
      );
    } catch (error) {
      await _activity.logLogin(
        firebaseUid: _activityIdentity(),
        identifier: phone?.trim() ?? 'invite_token',
        method: 'invite_access',
        success: false,
        errorMessage: _message(error),
      );
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_looksLikeEmail(normalizedEmail)) {
      state = state.copyWith(
        isLoading: false,
        error: 'Enter a valid email address to reset your password.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _firebase.sendPasswordResetEmail(normalizedEmail);
      await _activity.logLogin(
        firebaseUid: _activityIdentity(firebaseUid: _firebase.currentUser?.uid),
        identifier: normalizedEmail,
        method: 'password_reset',
        success: true,
      );
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (error) {
      await _activity.logLogin(
        firebaseUid: _activityIdentity(firebaseUid: _firebase.currentUser?.uid),
        identifier: normalizedEmail,
        method: 'password_reset',
        success: false,
        errorMessage: _message(error),
      );
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final credential = await _firebase.signInWithGoogle();
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Google sign-in failed to create a user session.');
      }
      final idToken = await firebaseUser?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google sign-in succeeded but token exchange failed.');
      }

      final result = await _repo.firebaseLogin(
        idToken: idToken,
        email: firebaseUser?.email,
        phone: firebaseUser?.phoneNumber,
        name: firebaseUser?.displayName,
      );
      await _persist(result);

      final identity = _activityIdentity(
        firebaseUid: firebaseUser?.uid,
        backendUserId: result.user.id,
      );

      await _activity.syncProfile(
        firebaseUid: identity,
        email: _profileEmail(firebaseUser?.email, result.user.email),
        name: result.user.name,
        phone: result.user.phone,
        role: result.user.globalRole,
      );
      await _activity.logLogin(
        firebaseUid: identity,
        identifier: _profileEmail(firebaseUser?.email, result.user.email),
        method: 'firebase_google',
        success: true,
        user: result.user,
      );
      await _activity.markSessionActive(
        firebaseUid: identity,
        user: result.user,
        token: result.token,
      );
    } on GoogleSignInCanceled {
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (error) {
      await _activity.logLogin(
        firebaseUid: _activityIdentity(firebaseUid: _firebase.currentUser?.uid),
        identifier: _firebase.currentUser?.email ?? 'google-user',
        method: 'firebase_google',
        success: false,
        errorMessage: _message(error),
      );
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<String> sendPhoneOtp(String phoneNumber) async {
    final normalized = phoneNumber.trim();
    if (normalized.isEmpty) {
      throw Exception('Phone number is required.');
    }

    return _firebase.sendPhoneOtp(normalized);
  }

  Future<void> verifyPhoneOtpAndLogin({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _firebase.verifyPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final firebaseUser = _firebase.currentUser;
      final idToken = await firebaseUser?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Phone verification succeeded but token exchange failed.',
        );
      }

      final result = await _repo.firebaseLogin(
        idToken: idToken,
        phone: phoneNumber,
        name: firebaseUser?.displayName,
        email: firebaseUser?.email,
      );
      await _persist(result);

      final identity = _activityIdentity(
        firebaseUid: firebaseUser?.uid,
        backendUserId: result.user.id,
      );

      await _activity.syncProfile(
        firebaseUid: identity,
        email: _profileEmail(firebaseUser?.email, result.user.email),
        name: result.user.name,
        phone: phoneNumber,
        role: result.user.globalRole,
      );
      await _activity.logLogin(
        firebaseUid: identity,
        identifier: phoneNumber,
        method: 'firebase_phone_otp',
        success: true,
        user: result.user,
      );
      await _activity.markSessionActive(
        firebaseUid: identity,
        user: result.user,
        token: result.token,
      );
    } catch (error) {
      await _activity.logLogin(
        firebaseUid: _activityIdentity(firebaseUid: _firebase.currentUser?.uid),
        identifier: phoneNumber,
        method: 'firebase_phone_otp',
        success: false,
        errorMessage: _message(error),
      );
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<void> switchRole(String role) async {
    await _store.saveActiveRole(role);
    state = state.copyWith(activeRole: role);
  }

  Future<void> logout() async {
    final identity = _activityIdentity(
      firebaseUid: _firebase.currentUser?.uid,
      backendUserId: state.user?.id,
    );

    try {
      await _repo.logout();
    } catch (_) {
      // ignore
    }

    await _activity.markSessionInactive(identity);

    try {
      await _firebase.signOut();
    } catch (_) {
      // ignore
    }

    await _store.clearSession();
    _realtime.disconnect();
    state = const AuthState(isBootstrapping: false, isLoading: false);
  }

  Future<void> _persist(AuthResult result) async {
    final role = result.participantRole ?? result.user.globalRole;
    await _store.saveToken(result.token);
    await _store.saveUser(result.user.toJson());
    await _store.saveActiveRole(role);
    _realtime.connect(result.token);
    state = AuthState(
      isBootstrapping: false,
      isLoading: false,
      token: result.token,
      user: result.user,
      activeRole: role,
    );
  }

  Future<void> _trackActiveSession(AppUser user, {String? token}) async {
    final identity = _activityIdentity(
      firebaseUid: _firebase.currentUser?.uid,
      backendUserId: user.id,
    );

    await _activity.syncProfile(
      firebaseUid: identity,
      email: _profileEmail(_firebase.currentUser?.email, user.email),
      name: user.name,
      phone: user.phone,
      role: user.globalRole,
    );
    await _activity.markSessionActive(
      firebaseUid: identity,
      user: user,
      token: token,
    );
  }

  bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  String _activityIdentity({String? firebaseUid, String? backendUserId}) {
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      return firebaseUid;
    }
    if (backendUserId != null && backendUserId.isNotEmpty) {
      return 'backend:$backendUserId';
    }
    return 'backend:anonymous';
  }

  String _profileEmail(String? preferred, String? fallback) {
    if (preferred != null && preferred.trim().isNotEmpty) {
      return preferred.trim().toLowerCase();
    }
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim().toLowerCase();
    }
    return 'unknown@flowsync.local';
  }

  String _message(Object error) {
    if (error is DioException) {
      final serverMessage = _serverMessage(error.response?.data);
      if (serverMessage != null) {
        return serverMessage;
      }

      return switch (error.type) {
        DioExceptionType.connectionTimeout =>
          'Server is taking too long to connect. Please try again.',
        DioExceptionType.receiveTimeout =>
          'Server is taking too long to respond. Please try again.',
        DioExceptionType.sendTimeout =>
          'Request timed out while sending. Please try again.',
        DioExceptionType.connectionError =>
          'Server unavailable. Please check your internet connection and try again.',
        _ => error.message ?? 'Something went wrong. Please try again.',
      };
    }

    if (error is FirebaseAuthException) {
      return error.message ?? 'Firebase authentication failed.';
    }

    final text = error.toString();
    if (text.contains('Cannot connect to server')) {
      return 'Server unavailable. Please make sure the backend is running.';
    }
    if (text.contains('connection timeout') ||
        text.contains('receive timeout')) {
      return 'Server is taking too long to respond. Please try again.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  String? _serverMessage(dynamic data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return null;
  }
}

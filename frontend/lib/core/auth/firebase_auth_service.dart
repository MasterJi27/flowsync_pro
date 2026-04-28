import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(FirebaseAuth.instance);
});

class GoogleSignInCanceled implements Exception {
  const GoogleSignInCanceled([
    this.message = 'Google sign-in was canceled by the user.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class FirebaseAuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;
  // google_sign_in v7 uses a singleton instance API.

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (displayName != null && displayName.trim().isNotEmpty) {
      await credential.user?.updateDisplayName(displayName.trim());
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: AppConfig.googleServerClientId.trim().isEmpty
            ? null
            : AppConfig.googleServerClientId.trim(),
        serverClientId: AppConfig.googleServerClientId.trim().isEmpty
            ? null
            : AppConfig.googleServerClientId.trim(),
      );

      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        throw const GoogleSignInCanceled();
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google ID token is missing. Verify the Firebase OAuth client IDs '
          'and SHA-1 fingerprints for this app.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      return _auth.signInWithCredential(credential);
    } on Exception catch (e) {
      if (e is GoogleSignInException) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          throw const GoogleSignInCanceled();
        }
      }
      rethrow;
    }
  }

  Future<String> sendPhoneOtp(String phoneNumber) {
    final completer = Completer<String>();

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete('auto');
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(error.message ?? 'Phone verification failed.'),
          );
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  Future<UserCredential?> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (verificationId == 'auto') {
      return null;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );

    return _auth.signInWithCredential(credential);
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  Future<void> signOut() {
    return Future.wait([
      _auth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]).then((_) => null);
  }
}

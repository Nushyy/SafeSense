import 'dart:async';

enum SapsSignInResult {
  ok,
  needsCode,
  badCredentials,
  notAuthorised,
  mfaNotSetUp,
  offline,
}

class OfficerProfile {
  const OfficerProfile({required this.name, this.station});
  final String name;
  final String? station;
}

/// What the officer login screen needs from the backend.
///
/// The screens only ever talk to this class. Today `main_saps.dart` plugs in
/// [MockSapsAuth] (fake data, no server). The backend owner plugs in a real
/// version in ONE place (main_saps.dart) and no screen changes.
/// See docs/SAPS_BACKEND_CONTRACT.md.
abstract class SapsAuthService {
  /// Set once at start-up in main_saps.dart.
  static late SapsAuthService instance;

  /// Fires whenever the officer is signed out (button, idle, or expired).
  Stream<void> get signedOut;

  /// Optional line shown under the login card (used by the demo version).
  String? get demoHint => null;

  /// Email + password. Must sign the person out and return
  /// [SapsSignInResult.notAuthorised] if the account is not an officer.
  Future<SapsSignInResult> signIn(String email, String password);

  /// Second step: 6-digit authenticator code. True if correct.
  Future<bool> verifyCode(String code);

  /// True only if a session exists AND the person is an officer AND any
  /// required verification code was completed. Used after a page reload.
  Future<bool> isFullyAuthorised();

  Future<OfficerProfile> profile();

  Future<void> signOut();
}

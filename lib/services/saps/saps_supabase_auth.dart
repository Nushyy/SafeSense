
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'saps_auth_service.dart';

class SupabaseSapsAuth extends SapsAuthService {
  final _signedOutController = StreamController<void>.broadcast();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<void> get signedOut => _signedOutController.stream;

  @override
  Future<SapsSignInResult> signIn(
    String email,
    String password,
  ) async {
    // Authentication happens through the main SafeSense login.
    return SapsSignInResult.notAuthorised;
  }

  @override
  Future<bool> verifyCode(String code) async {
    // The SAPS-specific mock verification code is not used.
    return false;
  }

  @override
  Future<bool> isFullyAuthorised() async {
    final user = _client.auth.currentUser;
    final session = _client.auth.currentSession;

    if (user == null || session == null) {
      return false;
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('role_id, approval_status')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null ||
          profile['role_id'] != 6 ||
          profile['approval_status'] != 'approved') {
        return false;
      }

      final officer = await _client
          .from('saps_officers')
          .select('verification_status')
          .eq('user_id', user.id)
          .maybeSingle();

      return officer != null &&
          officer['verification_status'] == 'verified';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<OfficerProfile> profile() async {
    if (!await isFullyAuthorised()) {
      throw StateError('SAPS Officer access required.');
    }

    final user = _client.auth.currentUser!;

    final officer = await _client
        .from('saps_officers')
        .select('station_name')
        .eq('user_id', user.id)
        .single();

    return OfficerProfile(
      name: user.email ?? 'SAPS Officer',
      station: officer['station_name'] as String?,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _signedOutController.add(null);
  }
}

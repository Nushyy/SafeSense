import 'package:supabase_flutter/supabase_flutter.dart';

class TrustedProfileMatch {
  const TrustedProfileMatch({
    required this.id,
    required this.username,
    required this.fullName,
  });

  final String id;
  final String username;
  final String fullName;

  factory TrustedProfileMatch.fromMap(Map<String, dynamic> map) {
    return TrustedProfileMatch(
      id: map['id'].toString(),
      username: (map['username'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
    );
  }

  String get displayUsername =>
      username.startsWith('@') ? username : '@$username';
}

class TrustedCircleEntry {
  const TrustedCircleEntry({
    required this.requestId,
    required this.personId,
    required this.username,
    required this.fullName,
    required this.status,
    required this.direction,
  });

  final String requestId;
  final String personId;
  final String username;
  final String fullName;
  final String status;
  final String direction;

  factory TrustedCircleEntry.fromMap(Map<String, dynamic> map) {
    return TrustedCircleEntry(
      requestId: map['request_id'].toString(),
      personId: map['person_id'].toString(),
      username: (map['username'] ?? '').toString(),
      fullName: (map['full_name'] ?? 'SafeSense user').toString(),
      status: (map['status'] ?? '').toString().toLowerCase(),
      direction: (map['direction'] ?? '').toString().toLowerCase(),
    );
  }

  String get displayUsername =>
      username.startsWith('@') ? username : '@$username';

  String get displayName => fullName.trim().isEmpty ? displayUsername : fullName;
}

class TrustedCircleRepository {
  TrustedCircleRepository._();

  static final SupabaseClient _client = Supabase.instance.client;

  static void _requireSignedIn() {
    if (_client.auth.currentUser == null) {
      throw StateError(
        'You are not signed in. Sign in to use your Trusted Circle.',
      );
    }
  }

  static Future<TrustedProfileMatch?> searchUsername(String username) async {
    _requireSignedIn();
    final clean = username.trim().replaceFirst(RegExp(r'^@'), '');
    if (clean.isEmpty) throw ArgumentError('Enter a username to search.');

    final result = await _client.rpc(
      'find_profile_by_username',
      params: {'p_username': clean},
    );
    final rows = result is List ? result : <dynamic>[];
    if (rows.isEmpty) return null;
    if (rows.length > 1) {
      throw StateError(
        'More than one SafeSense account uses that username. The database usernames need to be corrected before a request can be sent.',
      );
    }

    return TrustedProfileMatch.fromMap(
      Map<String, dynamic>.from(rows.first as Map),
    );
  }

  static Future<void> sendRequest(String username) async {
    _requireSignedIn();
    final clean = username.trim().replaceFirst(RegExp(r'^@'), '');
    if (clean.isEmpty) throw ArgumentError('Search for a username first.');

    await _client.rpc(
      'create_trusted_circle_request',
      params: {'p_username': clean},
    );
  }

  static Future<List<TrustedCircleEntry>> loadEntries() async {
    _requireSignedIn();
    final result = await _client.rpc('get_my_trusted_circle');
    if (result is! List) return <TrustedCircleEntry>[];

    return result
        .whereType<Map>()
        .map((row) => TrustedCircleEntry.fromMap(
              Map<String, dynamic>.from(row),
            ))
        .toList();
  }

  static Future<void> respond({
    required String requestId,
    required bool accept,
  }) async {
    _requireSignedIn();
    await _client.rpc(
      'respond_to_trusted_circle_request',
      params: {
        'p_request_id': requestId,
        'p_accept': accept,
      },
    );
  }

  static Future<void> remove(String requestId) async {
    _requireSignedIn();
    await _client.rpc(
      'remove_trusted_circle_member',
      params: {'p_request_id': requestId},
    );
  }
}

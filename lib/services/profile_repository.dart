import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRecord {
  const ProfileRecord({
    required this.id,
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    required this.neighborhood,
    required this.email,
  });

  final String id;
  final String fullName;
  final String username;
  final String phoneNumber;
  final String neighborhood;
  final String email;

  String get displayUsername {
    if (username.isEmpty) return '@user';
    return username.startsWith('@') ? username : '@$username';
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory ProfileRecord.fromMap(
    Map<String, dynamic> row, {
    required String id,
    required String email,
  }) {
    return ProfileRecord(
      id: id,
      fullName: (row['full_name'] ?? '').toString(),
      username: (row['username'] ?? '').toString(),
      phoneNumber: (row['phone_number'] ?? '').toString(),
      neighborhood: (row['neighborhood'] ?? '').toString(),
      email: email,
    );
  }
}

class ProfileRepository {
  ProfileRepository._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<ProfileRecord> loadCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'You are not signed in. Sign in to load your SafeSense profile.',
      );
    }

    final response = await _client
        .from('profiles')
        .select('id, username, full_name, phone_number, neighborhood')
        .eq('id', user.id)
        .maybeSingle();

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final row = response ?? <String, dynamic>{
      'id': user.id,
      'username': metadata['username'] ?? (user.email ?? 'user').split('@').first,
      'full_name': metadata['full_name'] ?? metadata['name'] ?? '',
      'phone_number': metadata['phone_number'] ?? '',
      'neighborhood': metadata['neighborhood'] ?? metadata['town'] ?? '',
    };

    return ProfileRecord.fromMap(
      row,
      id: user.id,
      email: user.email ?? '',
    );
  }

  static Future<ProfileRecord> saveCurrentProfile({
    required String fullName,
    required String username,
    required String phoneNumber,
    required String neighborhood,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'You are not signed in. Sign in before saving profile changes.',
      );
    }

    final cleanUsername = username.trim().replaceFirst(RegExp(r'^@'), '');
    if (cleanUsername.isEmpty) {
      throw ArgumentError('Enter a username.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]{3,30}$').hasMatch(cleanUsername)) {
      throw ArgumentError(
        'Username must be 3–30 characters and may contain letters, numbers, underscores, or periods.',
      );
    }
    if (fullName.trim().isEmpty) {
      throw ArgumentError('Enter your full name.');
    }

    final result = await _client.rpc(
      'save_my_profile',
      params: {
        'p_full_name': fullName.trim(),
        'p_username': cleanUsername,
        'p_phone_number': phoneNumber.trim(),
        'p_neighborhood': neighborhood.trim(),
      },
    );

    final List<dynamic> rows = result is List
        ? result
        : result == null
            ? <dynamic>[]
            : <dynamic>[result];

    if (rows.isEmpty || rows.first is! Map) {
      throw StateError(
        'Your profile could not be saved. Confirm that the SafeSense database setup SQL has been applied.',
      );
    }

    return ProfileRecord.fromMap(
      Map<String, dynamic>.from(rows.first as Map),
      id: user.id,
      email: user.email ?? '',
    );
  }
}

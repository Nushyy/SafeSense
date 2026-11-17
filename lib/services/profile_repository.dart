
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRecord {
  const ProfileRecord({
    required this.id,
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    required this.neighborhood,
    required this.email,
    this.avatarPath,
  });

  final String id;
  final String fullName;
  final String username;
  final String phoneNumber;
  final String neighborhood;
  final String email;
  final String? avatarPath;

  String get displayUsername {
    if (username.isEmpty) return '@user';
    return username.startsWith('@') ? username : '@$username';
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

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
      avatarPath: row['avatar_path']?.toString(),
    );
  }
}

class ProfileRepository {
  ProfileRepository._();

  static final SupabaseClient _client = Supabase.instance.client;

  static const String _avatarBucket = 'profile-photos';

  static Future<ProfileRecord> loadCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError(
        'You are not signed in. Sign in to load your SafeSense profile.',
      );
    }

    final response = await _client
        .from('profiles')
        .select(
          'id, username, full_name, phone_number, neighborhood, avatar_path',
        )
        .eq('id', user.id)
        .maybeSingle();

    final metadata = user.userMetadata ?? <String, dynamic>{};

    final row = response ?? <String, dynamic>{
      'id': user.id,
      'username':
          metadata['username'] ?? (user.email ?? 'user').split('@').first,
      'full_name': metadata['full_name'] ?? metadata['name'] ?? '',
      'phone_number': metadata['phone_number'] ?? '',
      'neighborhood': metadata['neighborhood'] ?? metadata['town'] ?? '',
      'avatar_path': null,
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

  // Uploads a new profile picture and saves its Storage path.
  static Future<ProfileRecord> uploadProfilePicture({
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to upload a profile picture.');
    }

    if (imageBytes.isEmpty) {
      throw ArgumentError('The selected image is empty.');
    }

    final extension = fileExtension.toLowerCase().replaceFirst('.', '');

    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError('Please select a JPG, PNG, or WebP image.');
    }

    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ArgumentError('Unsupported image format.'),
    };

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final newPath = '${user.id}/$timestamp.$extension';

    final oldProfile = await _client
        .from('profiles')
        .select('avatar_path')
        .eq('id', user.id)
        .maybeSingle();

    final oldPath = oldProfile?['avatar_path']?.toString();

    await _client.storage.from(_avatarBucket).uploadBinary(
      newPath,
      imageBytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: false,
      ),
    );

    try {
      await _client
          .from('profiles')
          .update({'avatar_path': newPath})
          .eq('id', user.id);

    } catch (error) {
      // Remove the newly uploaded file if saving its path fails.
      await _client.storage.from(_avatarBucket).remove([newPath]);
      rethrow;
    }

    // Delete the previous image after the new one has been saved.
    if (oldPath != null && oldPath.isNotEmpty) {
      try {
        await _client.storage.from(_avatarBucket).remove([oldPath]);
      } catch (_) {
        // The new profile picture is already saved.
      }
    }

    return loadCurrentProfile();
  }

  // Removes the current profile picture.
  static Future<ProfileRecord> removeProfilePicture() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to remove your profile picture.');
    }

    final response = await _client
        .from('profiles')
        .select('avatar_path')
        .eq('id', user.id)
        .maybeSingle();

    final oldPath = response?['avatar_path']?.toString();

    await _client
        .from('profiles')
        .update({'avatar_path': null})
        .eq('id', user.id);

    if (oldPath != null && oldPath.isNotEmpty) {
      await _client.storage.from(_avatarBucket).remove([oldPath]);
    }

    return loadCurrentProfile();
  }

  // Converts a Storage path into a public image URL.
  static String? getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }

    return _client.storage
        .from(_avatarBucket)
        .getPublicUrl(avatarPath);
  }
}

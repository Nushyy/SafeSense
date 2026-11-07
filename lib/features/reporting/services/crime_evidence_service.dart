import 'dart:typed_data';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads private evidence and links it to a report owned by the signed-in user.
class CrimeEvidenceService {
  CrimeEvidenceService(this._supabase);

  final SupabaseClient _supabase;

  static const int maxFileBytes = 50 * 1024 * 1024;
  static const int maxTotalBytes = 100 * 1024 * 1024;
  static const int maxFiles = 5;

  static const Map<String, String> supportedMimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'mp4': 'video/mp4',
    'webm': 'video/webm',
    'mov': 'video/quicktime',
  };

  Future<void> uploadEvidence({
    required String reportId,
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to upload evidence.');
    }
    if (bytes.isEmpty || bytes.length > maxFileBytes) {
      throw ArgumentError('File must be between 1 byte and 50 MB.');
    }

    final extension = originalFileName.split('.').last.toLowerCase();
    final mimeType = supportedMimeTypes[extension];
    if (mimeType == null) {
      throw ArgumentError('Unsupported evidence format.');
    }

    // Use a random UUID rather than trusting user-provided filenames as paths.
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}.$extension';
    final objectPath = '${user.id}/$reportId/$fileName';
    final storage = _supabase.storage.from('report-evidence');

    await storage.uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: false),
    );

    try {
      await _supabase.from('report_evidence').insert({
        'report_id': reportId,
        // This is a private Storage path, not a publicly accessible URL.
        'file_url': objectPath,
        'file_type': mimeType.startsWith('image/') ? 'image' : 'video',
      });
    } catch (_) {
      // Best-effort cleanup if the database record cannot be created.
      // A Storage DELETE policy is needed for this removal to succeed.
      try {
        await storage.remove([objectPath]);
      } catch (_) {
        // Keep the original database error; an orphan may need cleanup.
      }
      rethrow;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Name of the Supabase Storage bucket that holds profile pictures.
/// CHANGE THIS if your team stored profile pictures in a bucket with another name.
const kAvatarBucket = 'profile-photos';

/// Turns profiles.avatar_path into a picture link (null = no picture, show initials).
/// Works with a full link (https://...) or a path inside the bucket.
String? avatarUrlFromPath(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  if (path.startsWith('http')) return path;
  try {
    return sb.Supabase.instance.client.storage
        .from(kAvatarBucket)
        .getPublicUrl(path);
  } catch (_) {
    return null;
  }
}
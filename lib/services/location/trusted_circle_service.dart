import 'package:latlong2/latlong.dart';

import '../../models/trusted_circle_member.dart';
import '../database/supabase_service.dart';

class TrustedCircleService {
  final _supabase = SupabaseService.client;

  // Signed URLs are cached so avatars don't reload on every refresh
  final Map<String, String> _urlCache = {};
  final Map<String, DateTime> _urlCacheTime = {};

  Future<String?> _avatarUrl(String? rawPath) async {
    if (rawPath == null || rawPath.trim().isEmpty) return null;

    var path = rawPath.trim();

    if (path.startsWith('http')) return path;
    if (path.startsWith('profile_photos/')) {
      path = path.substring('profile_photos/'.length);
    }

    final cachedAt = _urlCacheTime[path];
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt).inMinutes < 50) {
      return _urlCache[path];
    }

    try {
      final url = await _supabase.storage
          .from('profile_photos')
          .createSignedUrl(path, 3600);

      _urlCache[path] = url;
      _urlCacheTime[path] = DateTime.now();
      return url;
    } catch (e) {
      print("AVATAR URL ERROR ($path): $e");
      return null;
    }
  }

  /// Everyone in the user's accepted circle, with their location
  /// when they're sharing it.
  Future<List<TrustedCircleMember>> getTrustedMembers() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return [];

    final requests = await _supabase
        .from('trusted_circle_requests')
        .select('requester_id, recipient_id')
        .eq('status', 'accepted')
        .or('requester_id.eq.${user.id},recipient_id.eq.${user.id}');

    final ids = <String>{};

    for (final r in (requests as List)) {
      final other =
          r['requester_id'] == user.id ? r['recipient_id'] : r['requester_id'];
      ids.add(other.toString());
    }

    if (ids.isEmpty) return [];

    final idList = ids.toList();

    final profiles = await _supabase
        .from('profiles')
        .select('id, full_name, avatar_path')
        .inFilter('id', idList);

    // Row-level security only returns people who are sharing with this user
    final locations = await _supabase
        .from('user_locations')
        .select('user_id, latitude, longitude')
        .inFilter('user_id', idList);

    final locationById = <String, LatLng>{};

    for (final row in (locations as List)) {
      locationById[row['user_id'].toString()] = LatLng(
        (row['latitude'] as num).toDouble(),
        (row['longitude'] as num).toDouble(),
      );
    }

    final members = <TrustedCircleMember>[];

    for (final p in (profiles as List)) {
      final id = p['id'].toString();
      final fullName = (p['full_name'] ?? '').toString().trim();

      members.add(
        TrustedCircleMember(
          id: id,
          name: fullName.isEmpty ? 'Member' : fullName.split(' ').first,
          location: locationById[id],
          avatarUrl: await _avatarUrl(p['avatar_path']?.toString()),
        ),
      );
    }

    return members;
  }

  /// Saves this user's own GPS so their circle can see them.
  Future<void> updateMyLocation(double lat, double lng) async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    try {
      await _supabase.from('user_locations').upsert({
        'user_id': user.id,
        'latitude': lat,
        'longitude': lng,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      print("UPDATE MY LOCATION ERROR: $e");
    }
  }
}
import 'package:latlong2/latlong.dart';

import '../../models/trusted_circle_member.dart';
import '../database/supabase_service.dart';

class TrustedCircleService {
  final _supabase = SupabaseService.client;

  // Cache resolved avatar URLs to avoid unnecessary lookups.
  final Map<String, String> _urlCache = {};

  Future<String?> _avatarUrl(String? rawPath) async {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return null;
    }

    var path = rawPath.trim();

    // Already a complete image URL.
    if (path.startsWith('https://') || path.startsWith('http://')) {
      return path;
    }

    // Remove any bucket prefix stored in the database.
    if (path.startsWith('profile-photos/')) {
      path = path.substring('profile-photos/'.length);
    } else if (path.startsWith('profile_photos/')) {
      path = path.substring('profile_photos/'.length);
    }

    if (_urlCache.containsKey(path)) {
      return _urlCache[path];
    }

    try {
      // Correct bucket: profile-photos
      // This bucket is configured as public in Supabase.
      final url = _supabase.storage.from('profile-photos').getPublicUrl(path);

      _urlCache[path] = url;

      return url;
    } catch (e) {
      print('TRUSTED CIRCLE AVATAR ERROR ($path): $e');
      return null;
    }
  }

  /// Retrieve accepted Trusted Circle members.
  Future<List<TrustedCircleMember>> getTrustedMembers() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    final requests = await _supabase
        .from('trusted_circle_requests')
        .select('requester_id, recipient_id')
        .eq('status', 'accepted')
        .or('requester_id.eq.${user.id},recipient_id.eq.${user.id}');

    final ids = <String>{};

    for (final request in requests) {
      final otherId = request['requester_id'] == user.id
          ? request['recipient_id']
          : request['requester_id'];

      if (otherId != null) {
        ids.add(otherId.toString());
      }
    }

    if (ids.isEmpty) {
      return [];
    }

    final idList = ids.toList();

    // RLS restricts profile access to authorized users.
    final profiles = await _supabase
        .from('profiles')
        .select('id, full_name, avatar_path')
        .inFilter('id', idList);

    // RLS enforces accepted relationships and location settings.
    final locations = await _supabase
        .from('user_locations')
        .select('user_id, latitude, longitude')
        .inFilter('user_id', idList);

    final locationById = <String, LatLng>{};

    for (final row in locations) {
      final latitude = row['latitude'];
      final longitude = row['longitude'];

      if (latitude is num && longitude is num) {
        locationById[row['user_id'].toString()] = LatLng(
          latitude.toDouble(),
          longitude.toDouble(),
        );
      }
    }

    final members = <TrustedCircleMember>[];

    for (final profile in profiles) {
      final id = profile['id'].toString();
      final fullName = (profile['full_name'] ?? '').toString().trim();

      members.add(
        TrustedCircleMember(
          id: id,
          name: fullName.isEmpty ? 'Member' : fullName.split(' ').first,
          location: locationById[id],
          avatarUrl: await _avatarUrl(profile['avatar_path']?.toString()),
        ),
      );
    }

    return members;
  }

  /// Update the signed-in user's saved GPS location.
  Future<void> updateMyLocation(double lat, double lng) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _supabase.from('user_locations').upsert({
        'user_id': user.id,
        'latitude': lat,
        'longitude': lng,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      print('UPDATE MY LOCATION ERROR: $e');
    }
  }
}

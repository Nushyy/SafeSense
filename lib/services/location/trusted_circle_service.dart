import 'package:latlong2/latlong.dart';

import '../../models/trusted_circle_member.dart';
import '../database/supabase_service.dart';

class TrustedCircleService {
  final _supabase = SupabaseService.client;

  /// Locations of everyone the security policy lets this user see
  /// (accepted circle members with sharing switched on).
  Future<List<TrustedCircleMember>> getTrustedMembers() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    final response = await _supabase
        .from('user_locations')
        .select('user_id, latitude, longitude, profiles(full_name)')
        .neq('user_id', user.id);

    return (response as List).map((row) {
      final fullName =
          (row['profiles']?['full_name'] ?? '').toString().trim();

      return TrustedCircleMember(
        id: row['user_id'].toString(),
        name: fullName.isEmpty ? 'Member' : fullName.split(' ').first,
        location: LatLng(
          (row['latitude'] as num).toDouble(),
          (row['longitude'] as num).toDouble(),
        ),
      );
    }).toList();
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
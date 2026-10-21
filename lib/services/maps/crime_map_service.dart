import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../models/crime_marker_model.dart';

class CrimeMapService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<CrimeMarkerModel>> getCrimeMarkers() async {
    final response = await supabase.from('report_locations').select('''
      latitude,
      longitude,
      crime_reports (
        id,
        created_at,
        crime_categories (
          name
        ),
        report_statuses (
          name
        )
      )
    ''');

    final markers = <CrimeMarkerModel>[];

    for (final item in (response as List)) {
      final report = item['crime_reports'];
      final lat = item['latitude'];
      final lng = item['longitude'];

      // Skip rows with missing joins or coordinates instead of crashing
      if (report == null || lat == null || lng == null) continue;

      markers.add(
        CrimeMarkerModel(
          id: report['id'].toString(),
          crimeType: (report['crime_categories']?['name'] ?? 'Other Crime')
              .toString(),
          status:
              (report['report_statuses']?['name'] ?? 'Unknown').toString(),
          location: LatLng(
            (lat as num).toDouble(),
            (lng as num).toDouble(),
          ),
          reportedAt: DateTime.parse(report['created_at']),
        ),
      );
    }

    return markers;
  }
}
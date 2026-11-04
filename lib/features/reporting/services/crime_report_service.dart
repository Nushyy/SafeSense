import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crime_report.dart';

class CrimeReportService {
  final SupabaseClient _supabase;

  CrimeReportService(this._supabase);

  Future<String> submitReport(
    CrimeReport report, {
    required String locationName,
  }) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw StateError('You must be logged in to submit a crime report.');
    }

    if (report.userId != currentUser.id) {
      throw StateError('The report user does not match the logged-in user.');
    }

    final trimmedLocation = locationName.trim();
    if (trimmedLocation.isEmpty || trimmedLocation.length > 200) {
      throw ArgumentError('Location name must contain 1 to 200 characters.');
    }

    final response = await _supabase.rpc(
      'submit_crime_report_with_location',
      params: {
        'p_category_id': report.categoryId,
        'p_description': report.description.trim(),
        'p_incident_datetime': report.incidentDateTime
            .toUtc()
            .toIso8601String(),
        'p_is_anonymous': report.isAnonymous,
        'p_location_name': trimmedLocation,
      },
    );

    if (response is! String || response.isEmpty) {
      throw StateError('The database did not return a valid report ID.');
    }

    return response;
  }

  Future<List<Map<String, dynamic>>> getMyReports() async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw StateError('You must be logged in to view your reports.');
    }

    final response = await _supabase
        .from('crime_reports')
        .select(
          'id, user_id, category_id, status_id, '
          'description, incident_datetime, '
          'is_anonymous, created_at, location_name',
        )
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}


import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crime_report.dart';

class CrimeReportService {
  final SupabaseClient _supabase;

  CrimeReportService(this._supabase);

  Future<String> submitReport(CrimeReport report) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw StateError(
        'You must be logged in to submit a crime report.',
      );
    }

    if (report.userId != currentUser.id) {
      throw StateError(
        'The report user does not match the logged-in user.',
      );
    }

    final reportData = report.toJson();

    final response = await _supabase
        .from('crime_reports')
        .insert(reportData)
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getMyReports() async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw StateError(
        'You must be logged in to view your reports.',
      );
    }

    final response = await _supabase
        .from('crime_reports')
        .select(
          'id, user_id, category_id, status_id, '
          'description, incident_datetime, '
          'is_anonymous, created_at',
        )
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}

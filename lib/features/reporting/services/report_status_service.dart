
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_status.dart';

class ReportStatusService {
  final SupabaseClient _supabase;

  ReportStatusService(this._supabase);

  Future<List<ReportStatus>> getStatuses() async {
    final response = await _supabase
        .from('report_statuses')
        .select('id, name')
        .order('id', ascending: true);

    return response
        .map((row) => ReportStatus.fromJson(row))
        .toList();
  }
}
import '../database/supabase_service.dart';

class StatusService {

  final _supabase = SupabaseService.client;


  Future<List<String>> getStatuses() async {

    final response = await _supabase
        .from('report_statuses')
        .select('name')
        .order('name');


    final statuses = (response as List)
        .map(
          (status) => status['name'].toString(),
        )
        .toList();


    return [
      "All Status",
      ...statuses,
    ];

  }

}
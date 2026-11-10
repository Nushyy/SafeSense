import '../../models/crime_report.dart';
import '../database/supabase_service.dart';

class CrimeService {

  final _supabase = SupabaseService.client;


  Future<List<CrimeReport>> getCrimeReports({

    String? crimeCategory,

    String? status,

    DateTime? startDate,

    DateTime? endDate,

  }) async {


    var query = _supabase
        .from('crime_reports')
        .select('''
          id,
          description,
          incident_datetime,

          crime_categories(
            name
          ),

          report_statuses(
            name
          ),

          report_locations(
            latitude,
            longitude,
            address
          )

        ''');


    // Crime category filter
    if (crimeCategory != null &&
        crimeCategory != "All Crime") {

      query = query.eq(
        'crime_categories.name',
        crimeCategory,
      );

    }


    // Status filter
    if (status != null &&
        status != "All Status") {

      query = query.eq(
        'report_statuses.name',
        status,
      );

    }


    // Date filter
    if (startDate != null) {

      query = query.gte(
        'incident_datetime',
        startDate.toIso8601String(),
      );

    }


    if (endDate != null) {

      query = query.lte(
        'incident_datetime',
        endDate.toIso8601String(),
      );

    }


    final response = await query;


    return (response as List)
        .map(
          (crime) =>
              CrimeReport.fromJson(crime),
        )
        .toList();

  }



  Future<List<String>> getCrimeCategories() async {


    final response = await _supabase
        .from('crime_categories')
        .select('name')
        .order('name');


    return (response as List)
        .map(
          (item) =>
              item['name'].toString(),
        )
        .toList();

  }

}
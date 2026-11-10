import '../../models/area_stats.dart';
import '../database/supabase_service.dart';

class StatsService {

final _supabase = SupabaseService.client;

Future<AreaStats> getAreaStats() async {

final response = await _supabase
    .from('crime_reports')
    .select('''
      id,

      crime_categories(
        name
      ),

      report_statuses(
        name
      )

    ''');

final reports = response as List;

final totalCrimes = reports.length;

// ALL CRIME COUNTS
final Map<String,int> crimeCounts = {};

for(final report in reports){

final crime =
    report['crime_categories']?['name']
    ??
    "Unknown";

crimeCounts[crime] =
    (crimeCounts[crime] ?? 0) + 1;

}

// TOP CRIMES

final List<CrimeStat> topCrimes = 
crimeCounts.entries.map((entry){

final percent =
totalCrimes == 0
?
0.0
:
(entry.value / totalCrimes) * 100;

return CrimeStat(

name: entry.key,

count: entry.value,

percent: percent,

);

}).toList();

topCrimes.sort(
(a,b)=>b.count.compareTo(a.count)
);

// STATUS COUNTS
final Map<String,int> statusCounts = {};

for(final report in reports){

final status =
report['report_statuses']?['name']
??
"Unknown";

statusCounts[status] =
(statusCounts[status] ?? 0)+1;

}

// CRIME RATE
final double crimeRate =
totalCrimes == 0
?
0
:
(totalCrimes / 1000).clamp(0,1);

return AreaStats(
  totalIncidents: totalCrimes,
  crimeRate: crimeRate,
  topCrimes: topCrimes,
  statusBreakdown: statusCounts,
  allCrimeTotals: crimeCounts,
);

}

}
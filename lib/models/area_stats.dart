class AreaStats {
  final int totalIncidents;

  final double crimeRate;

  final List<CrimeStat> topCrimes;

  final Map<String, int> statusBreakdown;

  final Map<String, int> allCrimeTotals;

  const AreaStats({
    required this.totalIncidents,
    required this.crimeRate,
    required this.topCrimes,
    required this.statusBreakdown,
    required this.allCrimeTotals,
  });
}

class CrimeStat {
  final String name;

  final int count;

  final double percent;

  const CrimeStat({
    required this.name,
    required this.count,
    required this.percent,
  });
}
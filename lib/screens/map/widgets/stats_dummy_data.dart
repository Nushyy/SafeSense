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

const List<CrimeStat> topCrimes = [

  CrimeStat(
    name: "Vehicle Crime",
    count: 156,
    percent: 28,
  ),

  CrimeStat(
    name: "Burglary",
    count: 98,
    percent: 17.6,
  ),

  CrimeStat(
    name: "Robbery",
    count: 89,
    percent: 16,
  ),

  CrimeStat(
    name: "Anti-Social Behaviour",
    count: 72,
    percent: 12.9,
  ),

  CrimeStat(
    name: "Drugs",
    count: 41,
    percent: 7.4,
  ),

];
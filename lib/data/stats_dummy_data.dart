class AreaStats {
  final double crimeRate;

  final Map<String, int> topCrimes;

  final Map<String, int> statusBreakdown;

  final Map<String, int> allCrimeTotals;

  const AreaStats({
    required this.crimeRate,
    required this.topCrimes,
    required this.statusBreakdown,
    required this.allCrimeTotals,
  });
}

///
/// Dummy data for development.
/// Later this will come from Supabase.
///
const AreaStats areaStats = AreaStats(

  // Percentage shown in the animated ring
  crimeRate: 0.74,

  // Top 5 crimes
  topCrimes: {
    "Burglary": 28,
    "Vehicle Crime": 22,
    "Robbery": 19,
    "Shoplifting": 15,
    "Other Theft": 11,
  },

  // Status breakdown
  statusBreakdown: {
    "Still In Progress": 31,
    "Under Investigation": 24,
    "Offender Dealt With": 18,
    "No Further Action": 9,
  },

  // Every crime category
  allCrimeTotals: {

    "Antisocial Behaviour": 17,

    "Bicycle Theft": 5,

    "Burglary": 28,

    "Criminal Damage & Arson": 11,

    "Drugs": 8,

    "Other Crime": 9,

    "Other Theft": 11,

    "Possession of Weapons": 6,

    "Public Order": 12,

    "Robbery": 19,

    "Shoplifting": 15,

    "Theft from Person": 10,

    "Vehicle Crime": 22,

    "Violence & Sexual Offences": 14,
  },
);
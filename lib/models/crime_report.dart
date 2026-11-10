class CrimeReport {
  final String id;
  final String categoryName;
  final String statusName;
  final String? description;
  final DateTime incidentDatetime;
  final double latitude;
  final double longitude;
  final String? address;

  CrimeReport({
    required this.id,
    required this.categoryName,
    required this.statusName,
    this.description,
    required this.incidentDatetime,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory CrimeReport.fromJson(Map<String, dynamic> json) {
    return CrimeReport(
      id: json['id'].toString(),

      categoryName:
          json['crime_categories']?['name'] ?? 'Unknown',

      statusName:
          json['report_statuses']?['name'] ?? 'Unknown',

      description:
          json['description'],

      incidentDatetime:
          DateTime.parse(json['incident_datetime']),

      latitude:
          (json['report_locations']?['latitude'] ?? 0)
              .toDouble(),

      longitude:
          (json['report_locations']?['longitude'] ?? 0)
              .toDouble(),

      address:
          json['report_locations']?['address'],
    );
  }
}

class CrimeReport {
  final String userId;
  final int categoryId;
  final String description;
  final DateTime incidentDateTime;
  final bool isAnonymous;

  const CrimeReport({
    required this.userId,
    required this.categoryId,
    required this.description,
    required this.incidentDateTime,
    required this.isAnonymous,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'description': description.trim(),
      'incident_datetime':
          incidentDateTime.toUtc().toIso8601String(),
      'is_anonymous': isAnonymous,
    };
  }
}
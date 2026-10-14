
class ReportStatus {
  final int id;
  final String name;

  const ReportStatus({
    required this.id,
    required this.name,
  });

  factory ReportStatus.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReportStatus(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

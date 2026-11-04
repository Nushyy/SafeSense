enum CaseKind { sos, report }

enum CaseBucket { needsAction, inProgress, closed }

String statusLabel(String s) {
  switch (s) {
    case 'false_alarm':
      return 'False alarm';
    case 'cancelled':
      return 'Cancelled by user';
    default:
      return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }
}

String formatWait(Duration d) {
  if (d.inMinutes < 1) return '<1 min';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  return '${d.inDays} d';
}

String formatTime(DateTime t) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.day} ${months[t.month - 1]} ${two(t.hour)}:${two(t.minute)}';
}

/// One row of the `saps_cases` view (a report or an SOS alert).
class SapsCase {
  const SapsCase({
    required this.id,
    required this.kind,
    required this.title,
    required this.status,
    required this.createdAt,
    this.description,
    this.area,
    this.lat,
    this.lng,
    this.reporterName,
    this.reporterPhone,
    this.battery,
  });

  final String id;
  final CaseKind kind;
  final String title;
  final String? description;
  final String? area;
  final double? lat;
  final double? lng;
  final String status;
  final DateTime createdAt;
  final String? reporterName;
  final String? reporterPhone;
  final int? battery;

  factory SapsCase.fromMap(Map<String, dynamic> m) => SapsCase(
        id: m['id'] as String,
        kind: m['kind'] == 'sos' ? CaseKind.sos : CaseKind.report,
        title: (m['title'] as String?) ?? 'Report',
        description: m['description'] as String?,
        area: m['area'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        status: (m['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
        reporterName: m['reporter_name'] as String?,
        reporterPhone: m['reporter_phone'] as String?,
        battery: (m['battery'] as num?)?.toInt(),
      );

  SapsCase copyWith({String? status}) => SapsCase(
        id: id,
        kind: kind,
        title: title,
        description: description,
        area: area,
        lat: lat,
        lng: lng,
        status: status ?? this.status,
        createdAt: createdAt,
        reporterName: reporterName,
        reporterPhone: reporterPhone,
        battery: battery,
      );

  bool get isSos => kind == CaseKind.sos;
  String get kindKey => isSos ? 'sos' : 'report';

  /// The forward path a case follows, as stored in the database.
  List<String> get steps => isSos
      ? const ['active', 'responding', 'resolved']
      : const ['pending', 'verified', 'resolved'];

  /// Next forward status, or null when there is none.
  String? get nextStatus {
    final i = steps.indexOf(status);
    if (i < 0 || i >= steps.length - 1) return null;
    return steps[i + 1];
  }

  /// The "this was not a real case" ending.
  String get rejectStatus => isSos ? 'false_alarm' : 'rejected';

  CaseBucket bucketOf(String s) {
    if (s == steps[0]) return CaseBucket.needsAction;
    if (s == steps[1]) return CaseBucket.inProgress;
    return CaseBucket.closed;
  }

  CaseBucket get bucket => bucketOf(status);
  bool get isOpen => bucket != CaseBucket.closed;

  String get displayTitle {
    if (!isSos) return title;
    switch (status) {
      case 'active':
        return 'SOS active';
      case 'responding':
        return 'SOS responding';
      default:
        return 'SOS alert';
    }
  }

  Duration get waiting => DateTime.now().difference(createdAt);

  /// SOS: 3 minutes. Reports: 30 minutes.
  bool get overdue => isOpen && waiting.inMinutes > (isSos ? 3 : 30);

  bool get hasLocation => lat != null && lng != null;
}

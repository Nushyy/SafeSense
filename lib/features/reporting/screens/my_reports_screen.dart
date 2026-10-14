
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../components/BottomNav/bottom_nav_scaffold.dart';
import '../models/crime_category.dart';
import '../models/report_status.dart';
import '../services/crime_category_service.dart';
import '../services/crime_report_service.dart';
import '../services/report_status_service.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late final CrimeReportService _reportService;
  late final CrimeCategoryService _categoryService;
  late final ReportStatusService _statusService;

  late Future<_MyReportsData> _reportsFuture;

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;

    _reportService = CrimeReportService(supabase);
    _categoryService = CrimeCategoryService(supabase);
    _statusService = ReportStatusService(supabase);

    _reportsFuture = _loadReports();
  }

  Future<_MyReportsData> _loadReports() async {
    final results = await Future.wait<dynamic>([
      _reportService.getMyReports(),
      _categoryService.getCategories(),
      _statusService.getStatuses(),
    ]);

    return _MyReportsData(
      reports: results[0] as List<Map<String, dynamic>>,
      categories: results[1] as List<CrimeCategory>,
      statuses: results[2] as List<ReportStatus>,
    );
  }

  Future<void> _refreshReports() async {
    final future = _loadReports();

    setState(() {
      _reportsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error state.
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'Date unavailable';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _lookupCategory(
    List<CrimeCategory> categories,
    dynamic categoryId,
  ) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }

    return 'Unknown category';
  }

  String _lookupStatus(
    List<ReportStatus> statuses,
    dynamic statusId,
  ) {
    for (final status in statuses) {
      if (status.id == statusId) {
        return status.name;
      }
    }

    return 'Unknown status';
  }

  Widget _buildReportCard(
    Map<String, dynamic> report,
    _MyReportsData data,
  ) {
    final category = _lookupCategory(
      data.categories,
      report['category_id'],
    );

    final status = _lookupStatus(
      data.statuses,
      report['status_id'],
    );

    final description = report['description']?.toString() ?? '';

    final reportId = report['id']?.toString() ?? 'Unavailable';

    final incidentDate = _formatDate(report['incident_datetime']);

    final isAnonymous = report['is_anonymous'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(status),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('Incident: $incidentDate'),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.privacy_tip_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isAnonymous
                      ? 'Identity hidden from public reports'
                      : 'Non-anonymous report',
                ),
              ],
            ),

            const Divider(height: 24),

            const Text(
              'Report Reference',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            SelectableText(
              reportId,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      currentIndex: 2,
      title: 'My Reports',
      child: RefreshIndicator(
        onRefresh: _refreshReports,
        child: FutureBuilder<_MyReportsData>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Unable to load your reports.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _refreshReports,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data;

            if (data == null || data.reports.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  Icon(
                    Icons.assignment_outlined,
                    size: 56,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'You have not submitted any reports yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.reports.length,
              itemBuilder: (context, index) {
                return _buildReportCard(
                  data.reports[index],
                  data,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MyReportsData {
  final List<Map<String, dynamic>> reports;
  final List<CrimeCategory> categories;
  final List<ReportStatus> statuses;

  const _MyReportsData({
    required this.reports,
    required this.categories,
    required this.statuses,
  });
}

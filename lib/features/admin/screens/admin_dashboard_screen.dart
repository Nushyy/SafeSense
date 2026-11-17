import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = Supabase.instance.client;
  bool _loading = true;
  bool _processing = false;
  String? _error;
  String? _processingId;
  int _tab = 0;
  int? _citizens, _pendingCount, _reports, _sos;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> _pendingOfficers = [];
  String? _officerLoadError;
  List<int?> _monthlyReports = List.filled(6, null);
  List<int?> _monthlyUsers = List.filled(6, null);
  List<int?> _monthlySos = List.filled(6, null);
  late List<DateTime> _months;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<bool> _isAdmin() async {
    if (_db.auth.currentUser == null) return false;
    return await _db.rpc('is_safesense_admin') == true;
  }

  Future<int> _count(String table, {String? column, Object? value,
    DateTime? start, DateTime? end}) async {
    // Head-only count avoids downloading sensitive rows for KPI totals.
    var query = _db.from(table).select('id');
    if (column != null && value != null) query = query.eq(column, value);
    if (start != null) query = query.gte('created_at', start.toUtc().toIso8601String());
    if (end != null) query = query.lt('created_at', end.toUtc().toIso8601String());
    final result = await query.count(CountOption.exact);
    return result.count;
  }

  Future<int?> _safeCount(String table, {String? column, Object? value,
    DateTime? start, DateTime? end}) async {
    try {
      return await _count(table, column: column, value: value, start: start, end: end);
    } catch (e) {
      debugPrint('Analytics count unavailable ($table): $e');
      return null;
    }
  }

  Future<void> _refresh() async {
    if (_processing || _loading && _error == null && _monthsInitialized) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_db.auth.currentUser == null) {
        if (mounted) context.go('/login');
        return;
      }
      if (!await _isAdmin()) {
        if (mounted) context.go('/account-status');
        return;
      }
      final now = DateTime.now();
      final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
      final citizens = await _safeCount('profiles', column: 'role_id', value: 1);
      final pendingCount = await _safeCount('profiles', column: 'approval_status', value: 'pending');
      final reports = await _safeCount('crime_reports');
      final sos = await _safeCount('sos_alerts');
      final monthlyReports = <int?>[];
      final monthlyUsers = <int?>[];
      final monthlySos = <int?>[];
      for (final start in months) {
        final end = DateTime(start.year, start.month + 1);
        monthlyReports.add(await _safeCount('crime_reports', start: start, end: end));
        monthlyUsers.add(await _safeCount('profiles', start: start, end: end));
        monthlySos.add(await _safeCount('sos_alerts', start: start, end: end));
      }
      List<Map<String, dynamic>> pending = [];
      List<Map<String, dynamic>> activity = [];
      List<Map<String, dynamic>> pendingOfficers = [];
      String? officerLoadError;
      Set<String>? officerIds;
      try {
        final rows = await _db.from('saps_officers')
            .select('user_id, station_name, created_at, verification_status')
            .eq('verification_status', 'pending')
            .order('created_at', ascending: false).limit(100);
        pendingOfficers = List<Map<String, dynamic>>.from(rows);
        officerIds = pendingOfficers
            .map((row) => row['user_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty).toSet();
        if (officerIds.isNotEmpty) {
          final profiles = await _db.from('profiles')
              .select('id, full_name, username, approval_status, role_id')
              .inFilter('id', officerIds.toList());
          final profileById = {
            for (final p in profiles) p['id'].toString(): p,
          };
          pendingOfficers = pendingOfficers.map((officer) => {
            ...officer,
            ...?profileById[officer['user_id']?.toString()],
          }).toList();
        }
      } catch (e) {
        debugPrint('SAPS verification queue unavailable: $e');
        officerLoadError = 'Unable to load pending SAPS Officers. Check administrator permissions.';
      }
      try {
        final rows = await _db.from('profiles')
            .select('id, full_name, username, created_at, approval_status')
            .eq('role_id', 1).eq('approval_status', 'pending')
            .order('created_at', ascending: false).limit(100);
        pending = List<Map<String, dynamic>>.from(rows);
        // Fail closed: never offer Citizen approval if we cannot
        // distinguish pending SAPS applications from Citizens.
        if (officerIds == null) {
          pending = [];
        } else {
          pending.removeWhere((person) => officerIds!.contains(person['id']?.toString()));
        }
      } catch (e) { debugPrint('Pending registrations unavailable: $e'); }
      try {
        final rows = await _db.from('admin_audit_logs')
            .select('id, action, details, created_at')
            .order('created_at', ascending: false).limit(30);
        activity = List<Map<String, dynamic>>.from(rows);
      } catch (e) { debugPrint('Audit log unavailable: $e'); }
      if (!mounted) return;
      setState(() {
        _months = months;
        _citizens = citizens; _pendingCount = pendingCount;
        _reports = reports; _sos = sos;
        _monthlyReports = monthlyReports;
        _monthlyUsers = monthlyUsers;
        _monthlySos = monthlySos;
        _pending = pending; _activity = activity;
        _pendingOfficers = pendingOfficers;
        _officerLoadError = officerLoadError;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Admin dashboard load error: $e');
      if (mounted) setState(() { _error = 'Unable to load the dashboard.'; _loading = false; });
    }
  }

  bool get _monthsInitialized {
    try { return _months.length == 6; } catch (_) { return false; }
  }

  String _date(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (d == null) return 'Unknown date';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _confirmAction(Map<String, dynamic> person, bool approve) async {
    if (_processing) return;
    final id = person['id']?.toString();
    if (id == null || id.isEmpty) return;
    final name = (person['full_name']?.toString().trim().isNotEmpty ?? false)
        ? person['full_name'].toString() : (person['username']?.toString() ?? 'this Citizen');
    final action = approve ? 'Approve' : 'Reject';
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('$action Citizen'),
      content: Text('Are you sure you want to ${action.toLowerCase()} $name?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ],
    ));
    if (yes != true || !mounted) return;
    setState(() { _processing = true; _processingId = id; });
    try {
      if (!await _isAdmin()) throw Exception('Not authorized');
      await _db.rpc(approve ? 'admin_approve_citizen' : 'admin_reject_citizen',
          params: {'p_citizen_user_id': id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'Citizen approved.' : 'Citizen rejected.'),
        ));
      }
    } catch (e) {
      debugPrint('Approval operation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to complete the action.')));
      }
    } finally {
      if (mounted) {
        setState(() { _processing = false; _processingId = null; });
        await _refresh();
      }
    }
  }

  Future<void> _approveOfficer(Map<String, dynamic> officer) async {
    if (_processing) return;
    final userId = officer['user_id']?.toString();
    if (userId == null || userId.isEmpty) return;
    if (officer['role_id'] != 1 || officer['approval_status'] != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This application is not eligible for approval.'),
      ));
      return;
    }
    final name = officer['full_name']?.toString() ?? 'SAPS applicant';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify SAPS Officer'),
        content: Text(
          'Approve $name as a SAPS Officer? Only continue after '
          'independently checking their identity and authority. '
          'For this test, use synthetic data only.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Verify and approve')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _processing = true; _processingId = userId; });
    try {
      if (!await _isAdmin()) throw Exception('Administrator access required');
      await _db.rpc('admin_approve_saps_officer',
          params: {'p_officer_user_id': userId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('SAPS demonstration officer approved.'),
        ));
      }
    } catch (e) {
      debugPrint('SAPS Officer approval failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to approve SAPS Officer. Check logs and permissions.'),
        ));
      }
    } finally {
      if (mounted) {
        setState(() { _processing = false; _processingId = null; });
        await _refresh();
      }
    }
  }

  Future<void> _signOut() async {
    if (_processing) return;
    try {
      await _db.auth.signOut();
      if (mounted) context.go('/login');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to sign out.')));
      }
    }
  }

  Widget _metric(String title, int? value, IconData icon) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Icon(icon), const SizedBox(height: 12),
        Text(value?.toString() ?? 'Unavailable', style: Theme.of(context).textTheme.headlineMedium),
        Text(title)],
    )),
  );

  Widget _monthlyChart(String title, List<int?> values) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final valid = values.whereType<int>().toList();
    final maxValue = valid.isEmpty ? 1 : valid.reduce((a, b) => a > b ? a : b);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(height: 170, child: Row(crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(6, (i) {
            final value = values[i];
            final barHeight = value == null ? 0.0 : 105.0 * value / (maxValue == 0 ? 1 : maxValue);
            return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(value?.toString() ?? '—', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 5),
                Container(height: barHeight, decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))),
                const SizedBox(height: 8),
                Text(names[_months[i].month - 1], style: const TextStyle(fontSize: 12)),
              ])));
          }))),
      ],
    )));
  }

  Widget _insight(String title, List<int?> values) {
    final current = values[5], previous = values[4];
    String description;
    if (current == null || previous == null) {
      description = 'Statistics are unavailable for one or both months.';
    } else if (previous == 0) {
      description = current == 0 ? 'No activity in either month.'
          : '$current recorded this month, compared with none last month.';
    } else {
      final pct = ((current - previous) / previous * 100).abs().toStringAsFixed(1);
      description = current == previous ? 'No change from last month.'
          : '${current > previous ? 'Increased' : 'Decreased'} by $pct% compared with last month.';
    }
    return ListTile(leading: const Icon(Icons.insights), title: Text(title), subtitle: Text(description));
  }

  Widget _overview() => ListView(padding: const EdgeInsets.all(16), children: [
    Text('Platform Overview', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 12),
    LayoutBuilder(builder: (context, constraints) => GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: constraints.maxWidth >= 700 ? 4 : 2,
      childAspectRatio: constraints.maxWidth >= 700 ? 1.6 : 1.3,
      children: [
        _metric('Registered Citizens', _citizens, Icons.people_outline),
        _metric('Pending Accounts', _pendingCount, Icons.pending_actions),
        _metric('Crime Reports', _reports, Icons.description_outlined),
        _metric('SOS Alerts', _sos, Icons.sos),
      ],
    )),
    const SizedBox(height: 12),
    _monthlyChart('Crime reports — last 6 months', _monthlyReports),
    _monthlyChart('New profiles — last 6 months', _monthlyUsers),
    _monthlyChart('SOS alerts — last 6 months', _monthlySos),
    Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text('Monthly Insights', style: Theme.of(context).textTheme.titleMedium)),
      _insight('Crime reporting', _monthlyReports),
      _insight('New profiles', _monthlyUsers),
      _insight('SOS alerts', _monthlySos),
    ])),
    const Padding(padding: EdgeInsets.all(8), child: Text(
      'Statistics reflect records accessible to this administrator. '
      'An unavailable value indicates a query or permissions issue, not zero activity.',
      style: TextStyle(fontSize: 12))),
  ]);

  Widget _activityView() => ListView(padding: const EdgeInsets.all(16), children: [
    Text('Recent Administrator Activity', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 12),
    if (_activity.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24),
      child: Text('No accessible administrator activity records.'))),
    for (final item in _activity) Card(child: ListTile(
      leading: const Icon(Icons.history),
      title: Text(item['action']?.toString() ?? 'Administrative action'),
      subtitle: Text(item['details']?.toString() ?? 'No additional details'),
      trailing: Text(_date(item['created_at'])),
    )),
  ]);

  Widget _usersView() {
    final filtered = _pending.where((person) {
      final text = '${person['full_name'] ?? ''} ${person['username'] ?? ''}'.toLowerCase();
      return text.contains(_search.toLowerCase());
    }).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Citizen Approvals', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('${_pending.length} pending registrations loaded (up to 100)'),
      const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search), labelText: 'Search pending Citizens',
        border: OutlineInputBorder()), onChanged: (value) => setState(() => _search = value)),
      const SizedBox(height: 12),
      if (filtered.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24),
        child: Text('No matching pending Citizens.'))),
      for (final person in filtered) Card(child: Padding(
        padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(person['full_name']?.toString() ?? 'Name not provided',
                style: Theme.of(context).textTheme.titleMedium),
            Text('Username: ${person['username'] ?? 'Not provided'}'),
            Text('Registered: ${_date(person['created_at'])}'),
            const SizedBox(height: 12),
            if (_processingId == person['id']?.toString())
              const Center(child: CircularProgressIndicator())
            else Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: _processing ? null : () => _confirmAction(person, true),
                icon: const Icon(Icons.check), label: const Text('Approve'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: _processing ? null : () => _confirmAction(person, false),
                icon: const Icon(Icons.close), label: const Text('Reject'))),
            ]),
          ],
        ),
      )),
    ]);
  }

  Widget _officersView() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('SAPS Officer Verification',
          style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Approve officers only after independent verification. '
          'This test environment must use synthetic case data.'),
      const SizedBox(height: 16),
      if (_officerLoadError != null)
        Card(child: Padding(padding: const EdgeInsets.all(16),
          child: Text(_officerLoadError!))),
      if (_officerLoadError == null && _pendingOfficers.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(24),
          child: Text('No pending SAPS Officer applications.'))),
      for (final officer in _pendingOfficers)
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(officer['full_name']?.toString() ?? 'Applicant name unavailable',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Station: ${officer['station_name'] ?? 'Not provided'}'),
              Text('Submitted: ${_date(officer['created_at'])}'),
              Text('Verification: ${officer['verification_status'] ?? 'Unknown'}'),
              const SizedBox(height: 12),
              if (_processingId == officer['user_id']?.toString())
                const Center(child: CircularProgressIndicator())
              else
                FilledButton.icon(
                  onPressed: _processing || officer['role_id'] != 1 ||
                      officer['approval_status'] != 'pending'
                      ? null : () => _approveOfficer(officer),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Verify and approve'),
                ),
            ],
          ),
        )),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SafeSense Administrator'), actions: [
      IconButton(tooltip: 'Refresh', onPressed: _loading || _processing ? null : _refresh,
        icon: const Icon(Icons.refresh)),
      IconButton(tooltip: 'Sign out', onPressed: _processing ? null : _signOut,
        icon: const Icon(Icons.logout)),
    ]),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!), ElevatedButton(onPressed: _refresh, child: const Text('Try Again'))]))
      : IndexedStack(index: _tab, children: [_overview(), _activityView(), _usersView(), _officersView()]),
    bottomNavigationBar: NavigationBar(selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Activity'),
        NavigationDestination(icon: Icon(Icons.manage_accounts_outlined), label: 'Users'),
        NavigationDestination(icon: Icon(Icons.verified_user_outlined), label: 'SAPS'),
      ]),
  );
}

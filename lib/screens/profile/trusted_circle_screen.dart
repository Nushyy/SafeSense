import 'package:flutter/material.dart';

import '../../services/trusted_circle_repository.dart';
import 'add_trusted_user_screen.dart';

class TrustedCircleScreen extends StatefulWidget {
  const TrustedCircleScreen({super.key});

  @override
  State<TrustedCircleScreen> createState() => _TrustedCircleScreenState();
}

class _TrustedCircleScreenState extends State<TrustedCircleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<TrustedCircleEntry> _entries = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busyRequests = {};

  List<TrustedCircleEntry> get _friends =>
      _entries.where((entry) => entry.status == 'accepted').toList();

  List<TrustedCircleEntry> get _incoming =>
      _entries.where((entry) =>
          entry.status == 'pending' && entry.direction == 'incoming').toList();

  List<TrustedCircleEntry> get _outgoing =>
      _entries.where((entry) =>
          entry.status == 'pending' && entry.direction == 'outgoing').toList();

  int get _pendingCount => _incoming.length + _outgoing.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await TrustedCircleRepository.loadEntries();
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPerson() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTrustedUserScreen()),
    );
    if (mounted) await _load();
  }

  Future<void> _respond(TrustedCircleEntry entry, bool accept) async {
    setState(() => _busyRequests.add(entry.requestId));
    try {
      await TrustedCircleRepository.respond(
        requestId: entry.requestId,
        accept: accept,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? '${entry.displayName} is now in your Trusted Circle.'
                : 'Request declined.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyRequests.remove(entry.requestId));
    }
  }

  Future<void> _remove(TrustedCircleEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove trusted person?'),
        content: Text(
          'Remove ${entry.displayName} from your Trusted Circle? They will no longer appear as an accepted trusted person.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyRequests.add(entry.requestId));
    try {
      await TrustedCircleRepository.remove(entry.requestId);
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busyRequests.remove(entry.requestId));
    }
  }

  void _showError(Object error) {
    final message = error.toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Trusted Circle')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPerson,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add person'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  Color.lerp(colors.primary, colors.tertiary, 0.4)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Trusted Circle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_friends.length} trusted ${_friends.length == 1 ? 'person' : 'people'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  color: Colors.white,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              labelColor: colors.onPrimary,
              unselectedLabelColor: colors.onSurfaceVariant,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Trusted (${_friends.length})'),
                Tab(text: 'Requests ($_pendingCount)'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _errorState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _friendsTab(),
                          _requestsTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _friendsTab() {
    if (_friends.isEmpty) {
      return _emptyState(
        icon: Icons.people_outline,
        title: 'No trusted people yet',
        message: 'Search for an existing SafeSense username to invite someone.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _friends.length,
        separatorBuilder: (_, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = _friends[index];
          final colors = Theme.of(context).colorScheme;
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Text(
                  _initials(entry.displayName),
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                entry.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(entry.displayUsername),
              ),
              trailing: _busyRequests.contains(entry.requestId)
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'remove') _remove(entry);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove'),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _requestsTab() {
    if (_incoming.isEmpty && _outgoing.isEmpty) {
      return _emptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'No pending requests',
        message: 'Incoming and sent Trusted Circle requests will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          if (_incoming.isNotEmpty) ...[
            _sectionTitle('Incoming requests', _incoming.length),
            const SizedBox(height: 10),
            ..._incoming.map((entry) => _requestCard(entry, incoming: true)),
          ],
          if (_outgoing.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Sent requests', _outgoing.length),
            const SizedBox(height: 10),
            ..._outgoing.map((entry) => _requestCard(entry, incoming: false)),
          ],
        ],
      ),
    );
  }

  Widget _requestCard(TrustedCircleEntry entry, {required bool incoming}) {
    final colors = Theme.of(context).colorScheme;
    final busy = _busyRequests.contains(entry.requestId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Text(
                _initials(entry.displayName),
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.displayUsername,
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incoming ? 'Wants to join your Trusted Circle' : 'Waiting for their response',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (incoming)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Accept request',
                    onPressed: () => _respond(entry, true),
                    icon: Icon(Icons.check_circle, color: colors.primary),
                  ),
                  IconButton(
                    tooltip: 'Decline request',
                    onPressed: () => _respond(entry, false),
                    icon: Icon(Icons.cancel_outlined, color: colors.error),
                  ),
                ],
              )
            else
              Icon(Icons.hourglass_top, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Chip(
          label: Text('$count'),
          backgroundColor: colors.secondaryContainer,
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _errorState() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 46, color: colors.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

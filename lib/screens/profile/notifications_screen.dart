
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool crimeAlerts = true;
  bool emergencyAlerts = true;
  bool communityAnnouncements = true;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in to load notification settings.');
      }

      final data = await _supabase
          .from('user_settings')
          .select(
            'crime_alerts, emergency_alerts, community_announcements',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          crimeAlerts = data['crime_alerts'] as bool;
          emergencyAlerts = data['emergency_alerts'] as bool;
          communityAnnouncements =
              data['community_announcements'] as bool;
        });
      }
      // If no record exists yet, the default values remain in place.
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError =
              'Could not load notification settings. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _savePreference({
    required String column,
    required bool value,
    required ValueChanged<bool> updateLocalValue,
  }) async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in to save your settings.');
      }

      await _supabase.from('user_settings').upsert(
        {
          'user_id': user.id,
          column: value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      if (!mounted) return;
      setState(() => updateLocalValue(value));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save that setting. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadPreferences,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'NOTIFICATION PREFERENCES',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _notificationCard(
                      context,
                      icon: Icons.warning_amber_outlined,
                      iconColor: const Color(0xFFF57C00),
                      title: 'Crime Alerts',
                      subtitle:
                          'Receive alerts about reported incidents nearby',
                      value: crimeAlerts,
                      onChanged: (value) => _savePreference(
                        column: 'crime_alerts',
                        value: value,
                        updateLocalValue: (savedValue) {
                          crimeAlerts = savedValue;
                        },
                      ),
                    ),
                    _notificationCard(
                      context,
                      icon: Icons.emergency_outlined,
                      iconColor: colors.error,
                      title: 'Emergency Alerts',
                      subtitle:
                          'Receive important emergency notifications',
                      value: emergencyAlerts,
                      onChanged: (value) => _savePreference(
                        column: 'emergency_alerts',
                        value: value,
                        updateLocalValue: (savedValue) {
                          emergencyAlerts = savedValue;
                        },
                      ),
                    ),
                    _notificationCard(
                      context,
                      icon: Icons.campaign_outlined,
                      iconColor: const Color(0xFF00897B),
                      title: 'Community Announcements',
                      subtitle:
                          'Receive important SafeSense announcements',
                      value: communityAnnouncements,
                      onChanged: (value) => _savePreference(
                        column: 'community_announcements',
                        value: value,
                        updateLocalValue: (savedValue) {
                          communityAnnouncements = savedValue;
                        },
                      ),
                    ),
                    if (_saving)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
    );
  }

  Widget _notificationCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: _saving ? null : onChanged,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool crimeAlerts = true;
  bool emergencyAlerts = true;
  bool statusUpdates = true;
  bool communityAnnouncements = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
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
            subtitle: 'Receive alerts about reported incidents nearby',
            value: crimeAlerts,
            onChanged: (value) => setState(() => crimeAlerts = value),
          ),
          _notificationCard(
            context,
            icon: Icons.emergency_outlined,
            iconColor: colors.error,
            title: 'Emergency Alerts',
            subtitle: 'Receive important emergency notifications',
            value: emergencyAlerts,
            onChanged: (value) => setState(() => emergencyAlerts = value),
          ),
          _notificationCard(
            context,
            icon: Icons.assignment_outlined,
            iconColor: colors.primary,
            title: 'Report Updates',
            subtitle: 'Get updates when your reports change status',
            value: statusUpdates,
            onChanged: (value) => setState(() => statusUpdates = value),
          ),
          _notificationCard(
            context,
            icon: Icons.campaign_outlined,
            iconColor: const Color(0xFF00897B),
            title: 'Community Announcements',
            subtitle: 'Receive important SafeSense announcements',
            value: communityAnnouncements,
            onChanged: (value) => setState(() => communityAnnouncements = value),
          ),
          const SizedBox(height: 8),
          Text(
            'These preferences currently apply to this screen. Persisting them to your account and connecting push notifications requires notification settings and delivery logic in the database/backend.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

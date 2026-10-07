import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool crimeAlerts = true;
  bool emergencyAlerts = true;
  bool statusUpdates = true;
  bool communityAnnouncements = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Text(
              'NOTIFICATION PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _notificationCard(
            icon: Icons.warning_amber_outlined,
            title: 'Crime Alerts',
            subtitle: 'Receive alerts about reported incidents nearby',
            value: crimeAlerts,
            onChanged: (value) {
              setState(() => crimeAlerts = value);
            },
          ),

          _notificationCard(
            icon: Icons.emergency_outlined,
            title: 'Emergency Alerts',
            subtitle: 'Receive important emergency notifications',
            value: emergencyAlerts,
            onChanged: (value) {
              setState(() => emergencyAlerts = value);
            },
          ),

          _notificationCard(
            icon: Icons.assignment_outlined,
            title: 'Report Updates',
            subtitle: 'Get updates when your reports change status',
            value: statusUpdates,
            onChanged: (value) {
              setState(() => statusUpdates = value);
            },
          ),

          _notificationCard(
            icon: Icons.campaign_outlined,
            title: 'Community Announcements',
            subtitle: 'Receive important SafeSense announcements',
            value: communityAnnouncements,
            onChanged: (value) {
              setState(() => communityAnnouncements = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 7,
        ),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
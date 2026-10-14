import 'package:flutter/material.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  bool anonymousReporting = true;
  bool approximateLocation = true;
  bool profileVisibility = false;
  bool trustedCircleLocation = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Safety')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'PRIVACY SETTINGS',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _setting(
            context,
            title: 'Anonymous Reporting',
            subtitle: 'Allow reports to be submitted without publicly displaying your identity',
            value: anonymousReporting,
            onChanged: (value) => setState(() => anonymousReporting = value),
          ),
          _setting(
            context,
            title: 'Approximate Location',
            subtitle: 'Use an approximate area instead of your exact location when appropriate',
            value: approximateLocation,
            onChanged: (value) => setState(() => approximateLocation = value),
          ),
          _setting(
            context,
            title: 'Profile Visibility',
            subtitle: 'Allow other community members to see your public profile',
            value: profileVisibility,
            onChanged: (value) => setState(() => profileVisibility = value),
          ),
          _setting(
            context,
            title: 'Trusted Circle Location',
            subtitle: 'Allow members of your trusted circle to receive your shared location',
            value: trustedCircleLocation,
            onChanged: (value) => setState(() => trustedCircleLocation = value),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security_outlined, color: colors.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These controls are currently UI preferences. They must be connected to reporting, location-sharing and privacy logic before they change how data is processed.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _setting(
    BuildContext context, {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

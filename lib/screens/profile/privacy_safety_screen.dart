import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() =>
      _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState
    extends State<PrivacySafetyScreen> {
  bool anonymousReporting = true;
  bool approximateLocation = true;
  bool profileVisibility = false;
  bool trustedCircleLocation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Privacy & Safety',
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
              'PRIVACY SETTINGS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _setting(
            title: 'Anonymous Reporting',
            subtitle:
                'Allow reports to be submitted without publicly displaying your identity',
            value: anonymousReporting,
            onChanged: (value) {
              setState(() => anonymousReporting = value);
            },
          ),

          _setting(
            title: 'Approximate Location',
            subtitle:
                'Use an approximate area instead of your exact location when appropriate',
            value: approximateLocation,
            onChanged: (value) {
              setState(() => approximateLocation = value);
            },
          ),

          _setting(
            title: 'Profile Visibility',
            subtitle:
                'Allow other community members to see your public profile',
            value: profileVisibility,
            onChanged: (value) {
              setState(() => profileVisibility = value);
            },
          ),

          _setting(
            title: 'Trusted Circle Location',
            subtitle:
                'Allow members of your trusted circle to receive your shared location',
            value: trustedCircleLocation,
            onChanged: (value) {
              setState(() => trustedCircleLocation = value);
            },
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.security_outlined,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SafeSense is designed to give you control over what information you share and who you share it with.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
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

  Widget _setting({
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
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
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
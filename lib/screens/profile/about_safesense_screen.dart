import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AboutSafeSenseScreen extends StatelessWidget {
  const AboutSafeSenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text(
          'About SafeSense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1976D2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 52,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'SafeSense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Community Safety Platform',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _infoCard(
            title: 'About SafeSense',
            icon: Icons.shield_outlined,
            text:
                'SafeSense is a community-focused safety platform designed to help users report incidents, receive safety alerts, connect with trusted people and access important safety information.',
          ),

          const SizedBox(height: 12),

          _infoCard(
            title: 'Our Goal',
            icon: Icons.visibility_outlined,
            text:
                'SafeSense aims to improve community awareness by bringing reporting, alerts, location-based safety information and trusted-circle features into one platform.',
          ),

          const SizedBox(height: 12),

          _infoCard(
            title: 'Version',
            icon: Icons.info_outline,
            text: 'SafeSense • Version 1.0.0',
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
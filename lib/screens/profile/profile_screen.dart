import 'package:flutter/material.dart';

import '../../models/profile_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

import 'edit_profile_screen.dart';
import 'personal_details_screen.dart';
import 'notifications_screen.dart';
import 'privacy_safety_screen.dart';
import 'trusted_circle_screen.dart';
import 'emergency_contacts_screen.dart';
import 'about_safesense_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Temporary activity data.
  // These will later come from Supabase.
  final int reportsCount = 12;
  final int alertsCount = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(
                context,
                isDark,
              ),

              const SizedBox(height: 20),

              _buildActivityStats(
                context,
                reportsCount,
                alertsCount,
              ),

              const SizedBox(height: 28),

              _buildSectionHeading(
                context,
                'ACCOUNT',
              ),

              const SizedBox(height: 12),

              _buildMenuCard(
                context,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF1976D2),
                    title: 'Personal Details',
                    subtitle:
                        'View your registered account information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PersonalDetailsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDivider(context),


                  _buildDivider(context),

                  _buildMenuItem(
                    context,
                    icon: Icons.people_alt_outlined,
                    iconColor: const Color(0xFF00897B),
                    title: 'Trusted Circle',
                    subtitle:
                        'Manage people you trust',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const TrustedCircleScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDivider(context),

                  _buildMenuItem(
                    context,
                    icon: Icons.contact_phone_outlined,
                    iconColor: const Color(0xFFE53935),
                    title: 'Emergency Contacts',
                    subtitle:
                        'Manage your emergency contacts',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _buildSectionHeading(
                context,
                'APP SETTINGS',
              ),

              const SizedBox(height: 12),

              _buildMenuCard(
                context,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none_outlined,
                    iconColor: const Color(0xFFF57C00),
                    title: 'Notifications',
                    subtitle:
                        'Manage your SafeSense alerts',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const NotificationsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDivider(context),

                  _buildMenuItem(
                    context,
                    icon: Icons.security_outlined,
                    iconColor: const Color(0xFF3949AB),
                    title: 'Privacy & Safety',
                    subtitle:
                        'Manage privacy and safety settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const PrivacySafetyScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDivider(context),

                  _buildDarkModeItem(
                    context,
                    isDark,
                  ),

                  _buildDivider(context),

                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF039BE5),
                    title: 'About SafeSense',
                    subtitle:
                        'Learn more about the SafeSense app',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AboutSafeSenseScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _buildLogoutButton(context),

              const SizedBox(height: 16),

              Text(
                'SafeSense • Version 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(
    BuildContext context,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBlue,
            AppColors.primaryBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.16),
              border: Border.all(
                color: Colors.white.withOpacity(0.65),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                ProfileData.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            ProfileData.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            ProfileData.username,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.white.withOpacity(0.85),
              ),
              const SizedBox(width: 4),
              Text(
                ProfileData.town,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const EditProfileScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              label: const Text(
                'Edit Profile',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.55),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITY STATS
  // ============================================================

  Widget _buildActivityStats(
    BuildContext context,
    int reports,
    int alerts,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.report_outlined,
            iconColor: const Color(0xFF1976D2),
            value: reports.toString(),
            label: 'Reports',
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.notifications_none_outlined,
            iconColor: const Color(0xFFF57C00),
            value: alerts.toString(),
            label: 'Alerts',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget _buildSectionHeading(
    BuildContext context,
    String title,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  // ============================================================
  // MENU CARD
  // ============================================================

  Widget _buildMenuCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _buildDivider(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      thickness: 1,
      indent: 74,
      endIndent: 16,
      color: colorScheme.outlineVariant.withOpacity(0.45),
    );
  }

  // ============================================================
  // DARK MODE
  // ============================================================

  Widget _buildDarkModeItem(
    BuildContext context,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    const lightModeColor = Color(0xFFF9A825);
    const darkModeColor = Color(0xFF5C6BC0);

    final iconColor =
        isDark ? darkModeColor : lightModeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  isDark
                      ? 'Dark appearance is enabled'
                      : 'Use a darker appearance',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: isDark,
            onChanged: (value) {
              AppThemeController.toggleDarkMode(value);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Widget _buildLogoutButton(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        _showLogoutDialog(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.danger.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.logout_outlined,
              color: AppColors.danger,
              size: 20,
            ),

            SizedBox(width: 9),

            Text(
              'Log Out',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,

          title: Text(
            'Log Out?',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),

          content: Text(
            'Are you sure you want to log out of SafeSense?',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Logout will be connected to authentication later.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// The navigation drawer opened from the SafeSense header.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  Future<void> _handleAuthentication(BuildContext context) async {
    final auth = Supabase.instance.client.auth;
    final isSignedIn = auth.currentUser != null;

    Navigator.of(context).pop();

    if (isSignedIn) {
      try {
        await auth.signOut();

        if (context.mounted) {
          context.go('/login');
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to log out. Please try again.'),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSignedIn =
        Supabase.instance.client.auth.currentUser != null;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // SafeSense branding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo_mark.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.shield_outlined,
                        size: 36,
                        color: AppColors.navy,
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'SafeSense',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color: AppColors.border,
            ),

            // Scrollable navigation
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () => _navigate(context, '/home'),
                  ),

                  _DrawerItem(
                    icon: Icons.map_outlined,
                    label: 'Map',
                    onTap: () => _navigate(context, '/map'),
                  ),

                  _DrawerItem(
                    icon: Icons.report_outlined,
                    label: 'Report',
                    onTap: () => _navigate(context, '/report'),
                  ),

                  _DrawerItem(
                    icon: Icons.campaign_outlined,
                    label: 'Alerts',
                    onTap: () => _navigate(context, '/alerts'),
                  ),

                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () => _navigate(context, '/profile'),
                  ),

                  // Inset blue divider
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Divider(
                      height: 2,
                      thickness: 2,
                      color: AppColors.navy,
                    ),
                  ),

                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () =>
                        _navigate(context, '/notifications'),
                  ),

                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: 'About',
                    onTap: () => _navigate(context, '/about'),
                  ),
                ],
              ),
            ),

            // Authentication action
            const Divider(
              height: 1,
              color: AppColors.border,
            ),

            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 12,
              ),
              child: _DrawerItem(
                icon: isSignedIn
                    ? Icons.logout
                    : Icons.login,
                label: isSignedIn
                    ? 'Log Out'
                    : 'Log In',
                onTap: () => _handleAuthentication(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A navigation row containing an icon and label.
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      leading: Icon(
        icon,
        color: AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }
}

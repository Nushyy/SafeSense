import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// The slide-out menu opened by the burger icon in the Header.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DrawerHeader(
              child: Row(
                children: [
                  Icon(Icons.shield, color: AppColors.teal, size: 28),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'SafeSense',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () => context.go('/home'),
            ),
            _DrawerItem(
              icon: Icons.description_outlined,
              label: 'My Reports',
              onTap: () => context.go('/report'),
            ),
            _DrawerItem(
              icon: Icons.campaign_outlined,
              label: 'Community Alerts',
              onTap: () => context.go('/alerts'),
            ),
            _DrawerItem(
              icon: Icons.alt_route_outlined,
              label: 'Safe Routes',
              onTap: () => context.push('/safe-route'),
            ),
            _DrawerItem(
              icon: Icons.contact_phone_outlined,
              label: 'Emergency Contacts',
              onTap: () => context.push('/emergency-contacts'),
            ),
            const Divider(color: AppColors.border),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),
            _DrawerItem(
              icon: Icons.language_outlined,
              label: 'Language (EN/ZU/AF)',
              onTap: () => context.push('/settings/language'),
            ),
            _DrawerItem(
              icon: Icons.help_outline,
              label: 'Help / SOS Info',
              onTap: () => context.push('/help'),
            ),
            const Spacer(),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Log out',
              onTap: () {
                // TODO(auth-owner): sign the user out, then go to '/login'.
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// One row in the drawer.
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
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: const TextStyle(color: AppColors.navy)),
      onTap: () {
        Navigator.of(context).pop(); // close the drawer first
        onTap(); // then go to the screen
      },
    );
  }
}
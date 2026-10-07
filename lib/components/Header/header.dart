import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// The top bar shown on every main screen:
/// app name on the left, bell and burger menu on the right.
class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key, this.title = 'SafeSense'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.shield, color: AppColors.teal, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications')),
            );
          },
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';



/// [hasUnread] shows a red dot on the bell. It defaults to false so the

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key, this.title = 'SafeSense', this.hasUnread = false});

  final String title;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // avoid a second, duplicate menu icon
      title: Row(
        children: [
          const Icon(Icons.shield, color: AppColors.tealText, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            isLabelVisible: hasUnread,
            smallSize: 9,
            backgroundColor: AppColors.danger,
            child: const Icon(Icons.notifications_outlined, size: 24),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications')),
            );
          },
        ),
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu, size: 26),
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
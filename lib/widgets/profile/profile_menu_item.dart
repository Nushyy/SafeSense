import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDanger;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemColor =
        isDanger ? AppColors.danger : AppColors.textPrimary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),

      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDanger
              ? AppColors.danger.withOpacity(0.1)
              : AppColors.lightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDanger
              ? AppColors.danger
              : AppColors.primaryBlue,
          size: 22,
        ),
      ),

      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            )
          : null,

      trailing: isDanger
          ? null
          : const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),

      onTap: onTap,
    );
  }
}
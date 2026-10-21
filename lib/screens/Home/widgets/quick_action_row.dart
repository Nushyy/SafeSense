import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}

const _actions = [
  _QuickAction(Icons.description_outlined, 'Report', '/report'),
  _QuickAction(Icons.campaign_outlined, 'Community', '/alerts'),
  _QuickAction(Icons.alt_route_outlined, 'SafeRoute', '/safe-route'),
  _QuickAction(Icons.phone_outlined, 'Contacts', '/emergency-contacts'),
];

class QuickActionRow extends StatelessWidget {
  const QuickActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final action in _actions)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _QuickActionButton(action: action),
            ),
          ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  void _navigate(BuildContext context) {
    if (action.route == '/report' || action.route == '/alerts') {
      context.go(action.route);
    } else {
      context.push(action.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${action.label}',
      child: InkWell(
        onTap: () => _navigate(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(action.icon, color: AppColors.navy, size: 25),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

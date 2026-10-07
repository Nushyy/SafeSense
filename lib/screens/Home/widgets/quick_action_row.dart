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
  _QuickAction(Icons.alt_route_outlined, 'Safe route', '/safe-route'),
  _QuickAction(Icons.phone_outlined, 'Contacts', '/emergency-contacts'),
];

/// Row of 4 quick-access shortcuts below the SOS button.
class QuickActionRow extends StatelessWidget {
  const QuickActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _actions.map((action) => _QuickActionButton(action: action)).toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // '/report' and '/alerts' are tabs, so we replace the screen.
        // The rest are one-off screens, so we push (keeps back button working).
        if (action.route == '/report' || action.route == '/alerts') {
          context.go(action.route);
        } else {
          context.push(action.route);
        }
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(action.icon, color: AppColors.navy, size: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(action.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
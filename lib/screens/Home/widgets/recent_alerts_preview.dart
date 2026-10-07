import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

class _AlertPreview {
  const _AlertPreview(this.icon, this.label, this.distance, this.time, this.color);
  final IconData icon;
  final String label;
  final String distance;
  final String time;
  final Color color;
}

// TODO(alerts-owner): replace with a real query for the latest reports.
const _placeholderAlerts = [
  _AlertPreview(Icons.warning_amber, 'Break-in reported', '0.4 km', '12 min ago', AppColors.danger),
  _AlertPreview(Icons.directions_car_outlined, 'Suspicious vehicle', '1.1 km', '40 min ago', AppColors.warning),
];

/// Shows the most recent nearby alerts, with a link to the full Alerts tab.
class RecentAlertsPreview extends StatelessWidget {
  const RecentAlertsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent alerts', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () => context.go('/alerts'), child: const Text('See all')),
          ],
        ),
        ..._placeholderAlerts.map(
          (alert) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: Icon(alert.icon, color: alert.color),
              title: Text(alert.label, style: Theme.of(context).textTheme.bodyMedium),
              subtitle: Text('${alert.distance} · ${alert.time}', style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ),
      ],
    );
  }
}
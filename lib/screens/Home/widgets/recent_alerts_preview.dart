import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Severity has a word as well as a colour, so it never relies on
/// colour alone.
enum AlertSeverity { high, medium, low }

extension AlertSeverityStyle on AlertSeverity {
  Color get tint {
    switch (this) {
      case AlertSeverity.high:
        return AppColors.danger.withValues(alpha: 0.12);
      case AlertSeverity.medium:
        return AppColors.warning.withValues(alpha: 0.2);
      case AlertSeverity.low:
        return AppColors.success.withValues(alpha: 0.14);
    }
  }

  Color get textColor {
    switch (this) {
      case AlertSeverity.high:
        return AppColors.dangerText;
      case AlertSeverity.medium:
        return AppColors.warningText;
      case AlertSeverity.low:
        return AppColors.successText;
    }
  }

  String get label {
    switch (this) {
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.low:
        return 'Low';
    }
  }
}

class _AlertPreview {
  const _AlertPreview(
    this.icon,
    this.label,
    this.distance,
    this.time,
    this.severity,
  );
  final IconData icon;
  final String label;
  final String distance;
  final String time;
  final AlertSeverity severity;
}


const _placeholderAlerts = [
  _AlertPreview(
    Icons.warning_amber_rounded,
    'Break-in reported',
    '0.4 km',
    '12 min ago',
    AlertSeverity.high,
  ),
  _AlertPreview(
    Icons.directions_car_outlined,
    'Suspicious vehicle',
    '1.1 km',
    '40 min ago',
    AlertSeverity.medium,
  ),
  _AlertPreview(
  Icons.person_search_outlined,
  'Suspicious person',
  '800 m',
  '15 min ago',
  AlertSeverity.medium,
),
];

/// The most recent nearby alerts, with a link to the full Alerts tab.
class RecentAlertsPreview extends StatelessWidget {
  const RecentAlertsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent alerts', style: textTheme.titleLarge),
            TextButton(
              onPressed: () => context.go('/alerts'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tealText,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        for (final alert in _placeholderAlerts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm - 2),
            child: Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                onTap: () => context.go('/alerts'),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: alert.severity.tint,
                        ),
                        child: Icon(
                          alert.icon,
                          size: 18,
                          color: alert.severity.textColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert.label, style: textTheme.bodyMedium),
                            Text(
                              '${alert.distance} · ${alert.time}',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: alert.severity.tint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alert.severity.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: alert.severity.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
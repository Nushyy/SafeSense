import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Risk level shown as a coloured badge. Calculated from recent report
/// counts once the reporting teammate's data is wired in.
enum RiskLevel { low, medium, high }

extension on RiskLevel {
  Color get color {
    switch (this) {
      case RiskLevel.low:
        return AppColors.success;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.danger;
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low risk';
      case RiskLevel.medium:
        return 'Medium risk';
      case RiskLevel.high:
        return 'High risk';
    }
  }
}

/// A quick summary of the area the user is currently in, with a link to
/// the full Map tab -- replaces the old map preview, which duplicated
/// the Map tab without adding anything a tap on that tab didn't show.
///
/// TODO(map-owner or reporting-owner): replace the hardcoded values below
/// with a real query: current area name from reverse-geocoding the
/// user's location, alert count from crime_reports in the last 24h,
/// and a risk level derived from that count / severity mix.
class AreaStatusCard extends StatelessWidget {
  const AreaStatusCard({
    super.key,
    this.areaName = 'Riverside',
    this.alertsLast24h = 3,
    this.risk = RiskLevel.medium,
  });

  final String areaName;
  final int alertsLast24h;
  final RiskLevel risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.navy, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text('You are in', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(areaName, style: Theme.of(context).textTheme.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: risk.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  risk.label,
                  style: TextStyle(color: risk.color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$alertsLast24h alert${alertsLast24h == 1 ? '' : 's'} reported nearby in the last 24 hours',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/map'),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('View on map'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
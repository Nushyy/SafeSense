import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../services/location/location_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Risk level shown as a badge. It always has an icon and a word, never
/// colour alone, so it works for people with colour-vision deficiency.
enum RiskLevel { low, medium, high }

extension RiskLevelStyle on RiskLevel {
  Color get tint {
    switch (this) {
      case RiskLevel.low:
        return AppColors.success.withValues(alpha: 0.14);
      case RiskLevel.medium:
        return AppColors.warning.withValues(alpha: 0.2);
      case RiskLevel.high:
        return AppColors.danger.withValues(alpha: 0.12);
    }
  }

  Color get textColor {
    switch (this) {
      case RiskLevel.low:
        return AppColors.successText;
      case RiskLevel.medium:
        return AppColors.warningText;
      case RiskLevel.high:
        return AppColors.dangerText;
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.low:
        return Icons.check_circle_outline;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.error_outline;
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


class AreaStatusCard extends StatefulWidget {
  const AreaStatusCard({super.key, this.alertsLast24h, this.risk});

  final int? alertsLast24h;
  final RiskLevel? risk;

  @override
  State<AreaStatusCard> createState() => _AreaStatusCardState();
}

class _AreaStatusCardState extends State<AreaStatusCard> {
  @override
  void initState() {
    super.initState();
    // Asks for permission when Home first appears, which is the moment
    // the card explains why it's needed.
    LocationService.instance.start();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LocationState>(
      valueListenable: LocationService.instance.state,
      builder: (context, location, _) {
        if (location.status == LocationStatus.ready) {
          return _ReadyCard(
            areaName: location.areaName,
            alertsLast24h: widget.alertsLast24h,
            risk: widget.risk,
          );
        }
        return _NoLocationCard(status: location.status);
      },
    );
  }
}

/// Location works: shows the area name. The whole card opens the Map.
class _ReadyCard extends StatelessWidget {
  const _ReadyCard({
    required this.areaName,
    required this.alertsLast24h,
    required this.risk,
  });

  final String? areaName;
  final int? alertsLast24h;
  final RiskLevel? risk;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = areaName ?? 'Finding your area…';
    final count = alertsLast24h;
    final level = risk;
    final plural = count == 1 ? '' : 's';

    final spoken = [
      'You are in $name',
      if (level != null) level.label,
      if (count != null) '$count alert$plural nearby in the last 24 hours',
      'Open map',
    ].join('. ');

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: spoken,
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () => context.go('/map'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm - 2),
                              Text('You are in · live', style: textTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                    if (level != null) _RiskBadge(risk: level),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        count == null
                            ? 'See what is happening nearby'
                            : '$count alert$plural nearby in the last 24 hours',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View map',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tealText,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.tealText,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Location isn't available: says why, and gives a way to fix it.
class _NoLocationCard extends StatelessWidget {
  const _NoLocationCard({required this.status});

  final LocationStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isLoading = status == LocationStatus.starting;

    var title = 'Finding your location…';
    String? message;
    String? actionLabel;
    VoidCallback? onAction;

    switch (status) {
      case LocationStatus.serviceOff:
        title = 'Location is off';
        message = 'Turn on location so SafeSense can show your area and '
            'share where you are in an SOS.';
        if (!kIsWeb) {
          actionLabel = 'Turn on location';
          onAction = () => Geolocator.openLocationSettings();
        }
      case LocationStatus.denied:
        title = 'Location permission needed';
        message = 'Allow location to see your area and share where you are '
            'in an SOS.';
        actionLabel = 'Allow location';
        onAction = () => LocationService.instance.retry();
      case LocationStatus.deniedForever:
        title = 'Location is blocked';
        if (kIsWeb) {
          message = 'Allow location for this site in your browser settings, '
              'then reload the page.';
        } else {
          message = 'Allow location for SafeSense in your phone settings.';
          actionLabel = 'Open settings';
          onAction = () => Geolocator.openAppSettings();
        }
      case LocationStatus.starting:
      case LocationStatus.ready:
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.location_off_outlined,
                  size: 18,
                  color: AppColors.warningText,
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm - 2),
            Text(message, style: textTheme.bodySmall),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md - 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tealText,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk});
  final RiskLevel risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: risk.tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(risk.icon, size: 14, color: risk.textColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            risk.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: risk.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
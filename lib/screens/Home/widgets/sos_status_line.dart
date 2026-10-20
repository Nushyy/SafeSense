import 'package:flutter/material.dart';
import '../../../services/location/location_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';


class SosStatusLine extends StatelessWidget {
  const SosStatusLine({super.key, this.connected});

  final bool? connected;

  String _message(LocationState location) {
    switch (location.status) {
      case LocationStatus.starting:
        return 'Finding your location…';
      case LocationStatus.serviceOff:
        return 'Location off · SOS cannot share where you are';
      case LocationStatus.denied:
      case LocationStatus.deniedForever:
        return 'Location blocked · SOS cannot share where you are';
      case LocationStatus.ready:
        if (connected == false) return 'No connection · Alert may not send';
        if (connected == true) return 'Location on · Connected';
        return 'Location on';
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;

    return ValueListenableBuilder<LocationState>(
      valueListenable: LocationService.instance.state,
      builder: (context, location, _) {
        final ready = location.isReady && connected != false;
        final starting = location.status == LocationStatus.starting;

        return Column(
          children: [
            Semantics(
              liveRegion: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: starting
                          ? AppColors.textSecondary
                          : ready
                              ? AppColors.success
                              : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm - 2),
                  Flexible(
                    child: Text(
                      _message(location),
                      style: style?.copyWith(
                        color: (ready || starting)
                            ? AppColors.textSecondary
                            : AppColors.warningText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.vibration,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm - 2),
                Text('Or shake your phone 3 times', style: style),
              ],
            ),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../services/location/location_service.dart';
import '../../../services/location/search_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// Displays the user's current location on the Home Dashboard.
///
/// Location is requested only when the user taps the button.
/// Crime risk and alert counts are not shown until verified data
/// becomes available.
class AreaStatusCard extends StatefulWidget {
  const AreaStatusCard({super.key});

  @override
  State<AreaStatusCard> createState() => _AreaStatusCardState();
}

class _AreaStatusCardState extends State<AreaStatusCard> {
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();

  Position? _position;
  String? _placeName;
  String? _message;
  bool _isLoading = false;

  Future<void> _getLocation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _message = null;
      _placeName = null;
      _position = null;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (!mounted) return;

      if (position == null) {
        setState(() {
          _message =
              'Location is unavailable. Check your device location '
              'settings and allow SafeSense to access your location.';
        });
        return;
      }

      setState(() {
        _position = position;
      });

      final placeName = await _searchService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _placeName = placeName;

        if (placeName == null || placeName.trim().isEmpty) {
          _message =
              'Your GPS location was found, but the place name '
              'could not be identified.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message =
            'Unable to retrieve your location. Please check your '
            'permissions and internet connection, then try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.navy,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Your Area',
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          if (_isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blue,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('Identifying your location...')),
              ],
            )
          else if (_position != null) ...[
            Text(
              _placeName ?? 'Location identified',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (_message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _message!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Area safety information is not available yet.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            Text(
              _message ??
                  'Enable location access to identify your '
                      'current area and explore the SafeSense map.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          if (!_isLoading)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _getLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  backgroundColor: AppColors.blue.withValues(alpha: 0.05),
                  side: BorderSide(
                    color: AppColors.blue.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(
                  _position == null ? Icons.my_location : Icons.refresh,
                ),
                label: Text(
                  _position == null ? 'Get my location' : 'Refresh location',
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.sm),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => context.go('/map'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('View map'),
              style: TextButton.styleFrom(foregroundColor: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

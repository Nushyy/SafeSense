
import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    try {
      // Check whether location services are enabled.
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled()
              .timeout(const Duration(seconds: 5));

      if (!serviceEnabled) {
        return null;
      }

      // Check location permissions.
      LocationPermission permission =
          await Geolocator.checkPermission()
              .timeout(const Duration(seconds: 5));

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Request a location with a bounded waiting period.
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw Exception(
        'GPS location request timed out. '
        'Please check your location settings and try again.',
      );
    } catch (e) {
      if (e is LocationServiceDisabledException ||
          e is PermissionDeniedException) {
        return null;
      }

      rethrow;
    }
  }
}

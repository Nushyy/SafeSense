import 'package:geolocator/geolocator.dart';

class LocationService {
  //get current user location
  Future<Position?> getCurrentLocation() async {

    //check if location services are enabled
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    //check location permission
    LocationPermission permission =
        await Geolocator.checkPermission();

    //ask user for permission if needed
    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.deniedForever) {
      return null;
    }

    //return current GPS position
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }
}
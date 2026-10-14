import 'package:latlong2/latlong.dart';

class MapService {
  //default location if GPS fails
  static const LatLng defaultLocation =
      LatLng(
        -26.2041,
        28.0473,
      ); //johannesburg, south africa


  //default zoom level
  static const double defaultZoom = 14.0;
}
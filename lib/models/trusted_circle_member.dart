import 'package:latlong2/latlong.dart';

class TrustedCircleMember {
  final String id;
  final String name;
  final LatLng location;

  TrustedCircleMember({
    required this.id,
    required this.name,
    required this.location,
  });

  factory TrustedCircleMember.fromJson(
      Map<String,dynamic> json) {

    return TrustedCircleMember(
      id: json['id'].toString(),
      name: json['name'],
      location: LatLng(
        json['latitude'],
        json['longitude'],
      ),
    );
  }
}
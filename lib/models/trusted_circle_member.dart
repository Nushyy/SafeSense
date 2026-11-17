
import 'package:latlong2/latlong.dart';

class TrustedCircleMember {
  final String id;
  final String name;
  final LatLng? location;
  final String? avatarUrl;

  const TrustedCircleMember({
    required this.id,
    required this.name,
    this.location,
    this.avatarUrl,
  });

  factory TrustedCircleMember.fromJson(
    Map<String, dynamic> json,
  ) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];

    LatLng? memberLocation;

    if (latitude is num && longitude is num) {
      memberLocation = LatLng(
        latitude.toDouble(),
        longitude.toDouble(),
      );
    }

    return TrustedCircleMember(
      id: json['id'].toString(),
      name: (json['name'] ?? json['full_name'] ?? 'Member')
          .toString(),
      location: memberLocation,
      avatarUrl: json['avatarUrl']?.toString() ??
          json['avatar_url']?.toString(),
    );
  }
}

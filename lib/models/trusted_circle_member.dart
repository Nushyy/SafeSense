import 'package:latlong2/latlong.dart';

class TrustedCircleMember {
  final String id;
  final String name;

  /// null when the member isn't sharing or hasn't uploaded a location yet
  final LatLng? location;

  final String? avatarUrl;

  TrustedCircleMember({
    required this.id,
    required this.name,
    this.location,
    this.avatarUrl,
  });

  factory TrustedCircleMember.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lng = json['longitude'];

    return TrustedCircleMember(
      id: json['id'].toString(),
      name: json['name'],
      location: (lat is num && lng is num)
          ? LatLng(lat.toDouble(), lng.toDouble())
          : null,
      avatarUrl: json['avatar_url'],
    );
  }
}
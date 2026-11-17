
import 'package:dio/dio.dart';

class SearchService {
  final Dio dio = Dio();

  /// Search for places using OpenStreetMap Nominatim.
  Future<List<dynamic>> searchPlaces(String query) async {
    final response = await dio.get(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': 1,
        'limit': 5,
      },
      options: Options(
        headers: {
          'User-Agent': 'SafeSenseApp',
        },
      ),
    );

    return response.data as List<dynamic>;
  }

  /// Convert GPS coordinates into a readable place name.
  Future<String> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'jsonv2',
          'zoom': 14,
          'addressdetails': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'SafeSenseApp',
          },
        ),
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        final address = data['address'];

        if (address is Map) {
          for (final key in [
            'suburb',
            'neighbourhood',
            'town',
            'city',
            'village',
            'county',
          ]) {
            final value = address[key];

            if (value is String && value.isNotEmpty) {
              return value;
            }
          }
        }

        final displayName = data['display_name'];

        if (displayName is String && displayName.isNotEmpty) {
          return displayName;
        }
      }
    } catch (error) {
      // Location lookup failure must not crash SafeSense.
    }

    return 'Unknown location';
  }
}

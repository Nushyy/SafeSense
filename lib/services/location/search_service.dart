import 'package:dio/dio.dart';

class SearchService {
  final Dio dio = Dio();

  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Search for places using a name or address.
  Future<List<dynamic>> searchPlaces(String query) async {
    final response = await dio.get(
      '$_baseUrl/search',
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': 1,
        'limit': 5,
      },
      options: Options(headers: {'User-Agent': 'SafeSenseApp'}),
    );

    return response.data;
  }

  /// Convert GPS coordinates into a short, readable location.
  ///
  /// Preferred format:
  /// Suburb, City
  ///
  /// Example:
  /// Universitas, Bloemfontein
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await dio.get(
        '$_baseUrl/reverse',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'format': 'jsonv2',
          'addressdetails': 1,
          'zoom': 16,
        },
        options: Options(headers: {'User-Agent': 'SafeSenseApp'}),
      );

      final data = response.data;

      if (data is! Map) {
        return null;
      }

      final address = data['address'];

      if (address is Map) {
        final suburb = _firstAvailable(address, [
          'suburb',
          'neighbourhood',
          'quarter',
          'city_district',
          'residential',
        ]);

        final city = _firstAvailable(address, [
          'city',
          'town',
          'village',
          'municipality',
          'county',
        ]);

        if (suburb != null && city != null) {
          if (suburb.toLowerCase() == city.toLowerCase()) {
            return city;
          }

          return '$suburb, $city';
        }

        if (city != null) {
          return city;
        }

        if (suburb != null) {
          return suburb;
        }
      }

      // Fallback when structured address fields are missing.
      final displayName = data['display_name'];

      if (displayName is String && displayName.trim().isNotEmpty) {
        final parts = displayName
            .split(',')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();

        if (parts.length >= 2) {
          return '${parts[0]}, ${parts[1]}';
        }

        if (parts.isNotEmpty) {
          return parts.first;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the first valid address field.
  String? _firstAvailable(Map address, List<String> keys) {
    for (final key in keys) {
      final value = address[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}

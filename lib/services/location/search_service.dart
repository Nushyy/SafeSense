import 'package:dio/dio.dart';

class SearchService {

  final Dio dio = Dio();

  Future<List<dynamic>> searchPlaces(String query) async {

    final response = await dio.get(
      "https://nominatim.openstreetmap.org/search",
      queryParameters: {
        "q": query,
        "format": "jsonv2",
        "addressdetails": 1,
        "limit": 5,
      },

      options: Options(
        headers: {
          "User-Agent": "SafeSenseApp"
        },
      ),
    );

    return response.data;
  }
}
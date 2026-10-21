import '../database/supabase_service.dart';


class CategoryService {

  final _supabase = SupabaseService.client;


  Future<List<String>> getCategories() async {

    final response = await _supabase
        .from('crime_categories')
        .select('name')
        .order('name');


    final categories = (response as List)
        .map(
          (category) =>
              category['name'].toString(),
        )
        .toList();


    return [
      "All Crime",
      ...categories,
    ];

  }

}
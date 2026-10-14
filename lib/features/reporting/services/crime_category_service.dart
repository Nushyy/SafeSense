import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crime_category.dart';

class CrimeCategoryService {
  final SupabaseClient _supabase;

  CrimeCategoryService(this._supabase);

  Future<List<CrimeCategory>> getCategories() async {
    final response = await _supabase
        .from('crime_categories')
        .select('id, name')
        .order('name', ascending: true);

    return response
        .map((row) => CrimeCategory.fromJson(row))
        .toList();
  }
}
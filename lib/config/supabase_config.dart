import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url =>
    dotenv.isInitialized ? (dotenv.maybeGet('SUPABASE_URL') ?? '') : '' ;
    static String get anonKey => dotenv.isInitialized ? (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '') : '';

    static bool get isConfigured => url.startsWith('http') && anonKey.isNotEmpty;
}

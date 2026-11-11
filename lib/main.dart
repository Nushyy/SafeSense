import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'community/bulletin_board_screen.dart';
import 'community/community_data.dart';
import 'community/supabase_community_repository.dart';
import 'config/supabase_config.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the Supabase details from .env (see .env.example).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('No .env file found: running on dummy data.');
  }

  // Use the real database when the details are there, otherwise dummy data.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    communityRepo = SupabaseCommunityRepository();
    unawaited(communityRepo.init());
  }

  runApp(const SafeSenseApp());
}

class SafeSenseApp extends StatelessWidget {
  const SafeSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const BulletinBoardScreen(),
    );
  }
}
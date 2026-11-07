
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/sos/sos_shake_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production configuration supplied during Flutter build.
  const buildSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  const buildSupabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  String supabaseUrl = buildSupabaseUrl;
  String supabasePublishableKey = buildSupabasePublishableKey;

  // Use the local .env file when build-time configuration
  // has not been provided.
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    await dotenv.load(fileName: '.env');

    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    supabasePublishableKey =
        dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
  }

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError(
      'Missing Supabase configuration. '
      'Provide SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
    );
  }

  // Initialize Supabase.
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  // Start SafeSense.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SafeSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,

      // Enable shake detection throughout the application.
      builder: (context, child) {
        return SosShakeListener(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/profile/profile_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Use the project URL, not the /rest/v1 endpoint.
    url: 'https://nqclujbxouwdgwqwjgvd.supabase.co',
    publishableKey: 'sb_publishable_XQc0PdNaSOTpQo5b-Jdc8g_k8gnFxGe',
  );

  await AppThemeController.loadSavedTheme();
  runApp(const SafeSenseApp());
}

class SafeSenseApp extends StatelessWidget {
  const SafeSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SafeSense',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const ProfileScreen(),
        );
      },
    );
  }
}

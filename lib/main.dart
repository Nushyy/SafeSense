import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/map/crime_map_screen.dart';

Future<void> main() async {
  // Required before any async work
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  runApp(const SafeSense());
}

class SafeSense extends StatelessWidget {
  const SafeSense({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeSense',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF172554),
      ),

      home: const CrimeMapScreen(),
    );
  }
}
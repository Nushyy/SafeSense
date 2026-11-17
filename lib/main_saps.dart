import 'package:flutter/material.dart';

import 'screens/Saps/saps_colors.dart';
import 'screens/Saps/saps_gate.dart';
import 'services/saps/saps_auth_service.dart';
import 'services/saps/saps_case_service.dart';
import 'services/saps/saps_mock_backend.dart';

// Separate entry point = separate app. The public SafeSense app never
// contains or links to this code. Run it with:
//
//   flutter run -d chrome -t lib/main_saps.dart
//
// It runs on DEMO data (no server needed):
//   officer@station.example · saps1234 · code 123456
//
// BACKEND OWNER: to connect the real backend, replace the two lines marked
// "BACKEND" below with your own subclasses of SapsAuthService and
// SapsCaseService. No screen needs to change.
// See docs/SAPS_BACKEND_CONTRACT.md.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SapsAuthService.instance = MockSapsAuth(); // BACKEND: swap for the real one
  SapsCaseService.instance = MockSapsCases(); // BACKEND: swap for the real one

  runApp(const SapsApp());
}

class SapsApp extends StatelessWidget {
  const SapsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSense · Law enforcement portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: SapsColors.blue,
          primary: SapsColors.blue,
          surface: SapsColors.surface,
        ),
        scaffoldBackgroundColor: SapsColors.background,
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: SapsColors.navy,
            side: const BorderSide(color: SapsColors.fieldBorder),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
        ),
      ),
      home: const SapsGate(),
    );
  }
}

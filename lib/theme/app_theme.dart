
import 'package:flutter/material.dart';

class AppTheme {
  // SafeSense brand colours.
  static const Color navy = Color(0xFF082E59);
  static const Color teal = Color(0xFF18B8AD);
  static const Color lightBackground = Color(0xFFF7FAFC);
  static const Color textDark = Color(0xFF102A43);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: lightBackground,

      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: navy,
        secondary: teal,
        surface: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFD9E2EC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: teal,
            width: 2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: teal,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }

          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return teal;
          }

          return null;
        }),
      ),
    );
  }
}

// ============================================================
// APP THEME CONTROLLER
// ============================================================

class AppThemeController {
  // Stores the current theme mode.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  // Existing method retained for compatibility.
  static void toggleDarkMode(bool enabled) {
    themeMode.value =
        enabled ? ThemeMode.dark : ThemeMode.light;
  }

  // New method required by the updated Profile screen.
  static void setDarkMode(bool enabled) {
    toggleDarkMode(enabled);
  }
}

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Compatibility facade for older screens. There is one source of truth:
/// AppThemeController, which also persists the preference.
class ThemeController {
  static ValueNotifier<ThemeMode> get themeMode =>
      AppThemeController.themeMode;

  static bool get isDarkMode =>
      AppThemeController.themeMode.value == ThemeMode.dark;

  static Future<void> toggleDarkMode(bool enabled) =>
      AppThemeController.setDarkMode(enabled);
}

import 'package:flutter/material.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDarkMode =>
      themeMode.value == ThemeMode.dark;

  static void toggleDarkMode(bool enabled) {
    themeMode.value =
        enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
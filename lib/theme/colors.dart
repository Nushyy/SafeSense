import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color navy = Color(0xFF0B2545);
  static const Color teal = Color(0xFF2BB3A3); // fills and decoration only
  static const Color tealText = Color(0xFF0F6E56); // text and icons (6:1 on white)
  static const Color blue = Color(0xFF1E5AA8);

  // Surfaces
  static const Color background = Color(0xFFF5F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDCE4EC);

  // Text
  static const Color textPrimary = navy;
  static const Color textSecondary = Color(0xFF5B6B80);

  // Status fills
  static const Color danger = Color(0xFFE32227);
  static const Color warning = Color(0xFFEF9F27);
  static const Color success = Color(0xFF2E9E6B);

  // Status text, dark enough to read on a light tint of the same colour
  static const Color dangerText = Color(0xFFA32D2D);
  static const Color warningText = Color(0xFF854F0B);
  static const Color successText = Color(0xFF3B6D11);
}
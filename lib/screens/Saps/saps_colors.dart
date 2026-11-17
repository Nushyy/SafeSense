import 'package:flutter/material.dart';

/// Colours for the SAPS case desk only. Sampled from the SAPS badge
/// (royal blue field, navy ring, gold star, yellow centre) and adjusted
/// so text passes contrast. Kept separate from AppColors so the public
/// app keeps the SafeSense look.
class SapsColors {
  SapsColors._();

  static const Color blue = Color(0xFF024596); // header, links
  static const Color navy = Color(0xFF1D2B58); // headings, selected filter
  static const Color gold = Color(0xFFD9B72B); // main action, accents
  static const Color goldLight = Color(0xFFF9EF68); // highlights on dark
  static const Color goldText = Color(0xFF5A4900); // text on gold tint
  static const Color goldTint = Color(0xFFFFF6CC);
  static const Color red = Color(0xFFB3261E); // SOS, overdue, close actions
  static const Color redText = Color(0xFF8A1F1A);
  static const Color redTint = Color(0xFFFBE3E1);
  static const Color green = Color(0xFF1B7A46); // done steps, live dot
  static const Color greenTint = Color(0xFFDDF3E6);
  static const Color blueTint = Color(0xFFCFE0F5);
  static const Color blueTintText = Color(0xFF012B5E);
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDCE2EE);
  static const Color fieldBorder = Color(0xFF8F9DB8);
  static const Color textSecondary = Color(0xFF44506B);
}

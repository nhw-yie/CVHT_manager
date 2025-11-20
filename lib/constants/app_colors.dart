import 'package:flutter/material.dart';

/// App color constants used across the app
class AppColors {
  // Design tokens (requested palette)
  static const Color primary = Color(0xFF1976D2); // #1976D2
  static const Color secondary = Color(0xFFFF6F00); // #FF6F00
  static const Color success = Color(0xFF4CAF50); // #4CAF50
  static const Color warning = Color(0xFFFFC107); // #FFC107
  static const Color error = Color(0xFFF44336); // #F44336
  static const Color background = Color(0xFFF5F5F5); // #F5F5F5
  static const Color surface = Color(0xFFFFFFFF); // #FFFFFF
  static const Color card = surface;
  // Backwards-compatibility aliases (some screens still reference older names)
  static const Color accent = AppColors.warning; // previously amber
  static const Color primaryVariant = Color(0xFF1565C0);
  static const Color danger = Color(0xFFD32F2F);
}

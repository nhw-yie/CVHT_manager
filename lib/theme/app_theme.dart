import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// Border radius constants
class AppRadius {
  static const double small = 8.0; // base radius
  static BorderRadius get base => BorderRadius.circular(small);
}

/// Provides a Material 3 ThemeData configured with the requested design tokens.
class AppTheme {
  static const String _fontFamily = 'Roboto';

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      background: AppColors.background,
      onBackground: Colors.black87,
      surface: AppColors.surface,
      onSurface: Colors.black87,
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      outline: Colors.grey,
      shadow: Colors.black,
      inverseSurface: Colors.grey.shade200,
      inversePrimary: AppColors.primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      fontFamily: _fontFamily,
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
        titleTextStyle: _buildTextTheme().titleLarge?.copyWith(color: colorScheme.onPrimary),
      ),
      cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: AppRadius.base), color: colorScheme.surface, elevation: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: AppRadius.base), backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: AppRadius.base))),
      inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: AppRadius.base)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: colorScheme.secondary, foregroundColor: colorScheme.onSecondary),
    );

    return base;
  }
}

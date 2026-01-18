import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from Stitch export
  static const Color primary = Color(0xFF107070);
  static const Color backgroundLight = Color(0xFFF9FAFA);
  static const Color backgroundDark = Color(0xFF121416);
  static const Color surfaceDark = Color(0xFF1C1F21);
  static const Color accentSuccess = Color(0xFF0BDA50);
  static const Color accentWarning = Color(0xFFFA5C38);
  static const Color critical = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF97316);
  static const Color info = Color(0xFF3B82F6);
  static const Color cardDark = Color(0xFF161616);

  // Text Styles
  static final TextTheme textTheme = GoogleFonts.manropeTextTheme();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accentSuccess,
        error: accentWarning,
        surface: Colors.white,
      ),
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFF0F172A), // slate-900
        displayColor: const Color(0xFF0F172A),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accentSuccess,
        error: accentWarning,
        surface: surfaceDark,
      ),
      textTheme: textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}

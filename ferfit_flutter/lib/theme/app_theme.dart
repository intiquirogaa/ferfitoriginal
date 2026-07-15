import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors matching Web OKLCH tokens
  static const Color primary = Color(0xFF1DD75B); // oklch(0.72 0.2 145) - Emerald green
  static const Color secondary = Color(0xFF8B5CF6); // oklch(0.6 0.2 300) - Purple accent
  static const Color background = Color(0xFF08090D); // oklch(0.08 0.01 240) - Dark slate bg
  static const Color backgroundDeep = Color(0xFF040507); // oklch(0.05 0.01 240) - Deeper black bg
  
  static const Color cardSolid = Color(0xFF14151C); // oklch(0.14 0.015 240) - Solid card surface
  static const Color cardGlass = Color(0x7314151C); // Glassmorphism translucent card surface
  static const Color border = Color(0x66232530); // oklch(0.25 0.02 240 / 0.4) - Translucent border
  static const Color borderSolid = Color(0xFF232530); // Solid border
  
  static const Color foreground = Color(0xFFFAFAFA); // oklch(0.95 0.01 240) - White text
  static const Color mutedForeground = Color(0xFF94A3B8); // oklch(0.55 0.02 240) - Grey text
  static const Color error = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardSolid,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: AppColors.foreground,
        onBackground: AppColors.foreground,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.apply(
              bodyColor: AppColors.foreground,
              displayColor: AppColors.foreground,
            ),
      ),
      dividerColor: AppColors.borderSolid,
      useMaterial3: true,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1A6B00);
  static const Color primaryYellow = Color(0xFFF5C800);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0D0D0D);
  static const Color red = Color(0xFFFF4C4C);

  // M3 structural mappings
  static const Color background = primaryGreen;
  static const Color surface = primaryGreen;
  static const Color onBackground = white;
  static const Color onSurface = white;
}

class AppTheme {
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryYellow,
        onPrimary: AppColors.black,
        secondary: AppColors.primaryYellow,
        onSecondary: AppColors.black,
        error: AppColors.red,
        onError: AppColors.white,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rajdhani(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          height: 1.0,
          letterSpacing: 0.02 * 48,
          color: AppColors.primaryYellow,
        ),
        headlineLarge: GoogleFonts.rajdhani(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 36 / 32,
          color: AppColors.primaryYellow,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 28 / 24,
          color: AppColors.primaryYellow,
        ),
        headlineSmall: GoogleFonts.rajdhani(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 24 / 20,
          color: AppColors.primaryYellow,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 26 / 18,
          color: AppColors.white,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 24 / 16,
          color: AppColors.white,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 20 / 14,
          letterSpacing: 0.05 * 14,
          color: AppColors.black,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 16 / 12,
          color: AppColors.white,
        ),
      ),
      // Set default button theme to match brutalist style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.black,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.black, width: 2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05 * 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.white, width: 2),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05 * 14,
          ),
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.primaryGreen,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.black, width: 2),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.black,
        thickness: 2,
        space: 2,
      ),
    );
  }
}

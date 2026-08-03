// THEME LOCK: light — source: domain signal (EdTech, outdoor-readable)
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary palette — green (growth, data mastery)
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryContainer = Color(0xFFC8E6C9);
  static const Color primaryDark = Color(0xFF1B5E20);

  // Secondary palette — amber/yellow (energy, highlights)
  static const Color secondary = Color(0xFFF9A825);
  static const Color secondaryContainer = Color(0xFFFFF8E1);

  // Semantic colors
  static const Color success = Color(0xFF2D7A4F);
  static const Color warning = Color(0xFFF57F17);
  static const Color error = Color(0xFFB91C1C);
  static const Color info = Color(0xFF1565C0);

  // Light surfaces
  static const Color backgroundLight = Color(0xFFF5F7F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEEF2EE);

  // Dark surfaces
  static const Color backgroundDark = Color(0xFF121712);
  static const Color surfaceDark = Color(0xFF1E261E);
  static const Color surfaceVariantDark = Color(0xFF2A342A);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: primaryDark,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: const Color(0xFF5D3A00),
      surface: surfaceLight,
      onSurface: const Color(0xFF1A1A1A),
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: const Color(0xFF444444),
      error: error,
      onError: Colors.white,
      outline: const Color(0xFFCCCCCC),
      outlineVariant: const Color(0xFFEEEEEE),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.dmSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primaryContainer,
      labelStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: primaryDark,
      onPrimaryContainer: const Color(0xFFC8E6C9),
      secondary: secondary,
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF4A3200),
      onSecondaryContainer: const Color(0xFFFFE082),
      surface: surfaceDark,
      onSurface: const Color(0xFFE6E6E6),
      surfaceContainerHighest: surfaceVariantDark,
      onSurfaceVariant: const Color(0xFFAAAAAA),
      error: const Color(0xFFCF6679),
      onError: Colors.white,
      outline: const Color(0xFF4A4A4A),
      outlineVariant: const Color(0xFF2E2E2E),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.dmSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE6E6E6),
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE6E6E6),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6E6E6),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE6E6E6),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFFAAAAAA),
        ),
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
    ),
  );
}

import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF0D9488); // Modern Teal
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  
  // Service Category Colors
  static const Color groomingColor = Color(0xFF3B82F6); // Blue
  static const Color sterilColor = Color(0xFF8B5CF6);   // Purple
  static const Color hotelColor = Color(0xFFF97316);    // Orange

  // Pickup Status Highlights
  static const Color readyGreen = Color(0xFF10B981);   // Bright Emerald for "SIAP DIJEMPUT"
  static const Color readyGreenBg = Color(0xFFD1FAE5);
  static const Color inProgressAmber = Color(0xFFF59E0B);
  static const Color inProgressBg = Color(0xFFFEF3C7);
  static const Color delayedRed = Color(0xFFEF4444);    // Overdue pickup warning
  static const Color delayedRedBg = Color(0xFFFEE2E2);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: const Color(0xFFF59E0B),
        surface: cardSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}

import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6699CC);
  static const Color accentColor = Color(0xFFFF6699);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color dangerColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color cardBg = Color(0xFF16213E);
  static const Color surfaceColor = Color(0xFF0F3460);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardBg,
        error: dangerColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
    );
  }

  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }

  static BoxDecoration get gradientButton {
    return BoxDecoration(
      gradient: const LinearGradient(colors: [primaryColor, accentColor]),
      borderRadius: BorderRadius.circular(12),
    );
  }
}

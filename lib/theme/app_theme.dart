import 'package:flutter/material.dart';

class AppTheme {
  static const String arabicFontFamily = 'Amiri';
  static const String banglaFontFamily = 'HindSiliguri';
  static const String banglaSerifFontFamily = 'TiroBangla';

  static const Color emeraldPrimary = Color(0xFF0F5132);
  static const Color emeraldLight = Color(0xFF198754);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color creamBackground = Color(0xFFF7F5EF);
  static const Color darkBackground = Color(0xFF0C1813);
  static const Color darkSurface = Color(0xFF13261E);

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: emeraldPrimary,
      primary: emeraldPrimary,
      secondary: goldAccent,
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: banglaFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: creamBackground,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: emeraldPrimary.withOpacity(0.10)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: emeraldPrimary,
      ),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: emeraldLight,
      primary: emeraldLight,
      secondary: goldAccent,
      surface: darkSurface,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: banglaFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: goldAccent.withOpacity(0.16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}

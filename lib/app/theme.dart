import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  // Brand palette extracted from logo.png.
  const primary = Color(0xFFD6246F);
  const secondary = Color(0xFF5B4AA0);
  const tertiary = Color(0xFFE79AB8);
  const surfaceTint = Color(0xFFC8C2E3);
  const bg = Color(0xFFF7F5FA);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surfaceTint: surfaceTint,
      background: bg,
    ),
    scaffoldBackgroundColor: bg,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8D0EA)),
      ),
      filled: true,
      fillColor: const Color(0xFFF5F1FA),
    ),
  );
}

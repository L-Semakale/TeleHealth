import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primary = Color(0xFF0A84FF);
  const secondary = Color(0xFF14B8A6);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      background: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FBFC),
    ),
  );
}

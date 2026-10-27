import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgMain = Color(0xFF0E111A);
  static const Color bgCard = Color(0xFF181D2A);
  static const Color primary = Color(0xFFFFC18F);
  static const Color cyan = Color(0xFF38EBD6);
  static const Color textMain = Colors.white;
  static const Color textMuted = Color(0xFF8E95A5);
  static const Color borderLight = Colors.white10;
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgMain,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: bgCard,
      ),
      fontFamily: 'Roboto', // Default fallback
    );
  }
}

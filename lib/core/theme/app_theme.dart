// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Цвета из нового дизайна
  static const Color bgDark = Color(0xFF262422); // Основной темный фон
  static const Color cardDark = Color(0xFF383430); // Цвет карточки
  static const Color accentYellow = Color(0xFFDC9F50); // Горчичный/Золотой
  static const Color textGrey = Color(0xFFAFAFAF); // Серый текст

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        surface: bgDark,
      ),
      fontFamily: 'San Francisco', // Или подключи 'Poppins' через google_fonts
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56), // Высота кнопок
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // Овальные кнопки (pill)
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
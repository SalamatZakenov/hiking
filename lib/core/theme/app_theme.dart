// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // --- НОВЫЕ ЦВЕТА (Для Onboarding и нового стиля) ---
  static const Color bgDark = Color(0xFF151921); // Глубокий темно-синий
  static const Color cardSlate = Color(0xFF8394A3); // Стальной сине-серый
  static const Color iconDark = Color(0xFF262D3A); // Темный кружок
  static const Color textLightGrey = Color(0xFFD4DBE1); // Светло-серый текст

  // --- СТАРЫЕ ЦВЕТА (Временно вернули, чтобы не ломались старые экраны) ---
  static const Color cardDark = Color(0xFF383430);
  static const Color accentYellow = Color(0xFFDC9F50);
  static const Color textGrey = Color(0xFFAFAFAF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark, // Фон теперь везде будет новый темный!
      colorScheme: const ColorScheme.dark(
        primary: cardSlate,
        surface: bgDark,
      ),
      fontFamily: 'San Francisco',
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cardSlate,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),
    );
  }
}
// lib/features/auth/presentation/auth_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Логотип (в стиле нового дизайна Onboarding)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.iconDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cardSlate.withOpacity(0.5), width: 4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.cardSlate, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.terrain_rounded, size: 36, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),

              // Заголовок
              const Text(
                'Sign up log in to start exploring',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),

              // Кнопки соцсетей
              _buildSocialButton(
                iconWidget: const Icon(Icons.apple, size: 28, color: Colors.white),
                label: 'Continue with Apple',
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              _buildSocialButton(
                // Имитация иконки Google
                iconWidget: _buildGooglePlaceholder(),
                label: 'Continue with Google',
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              _buildSocialButton(
                iconWidget: const Icon(Icons.facebook, size: 28, color: Color(0xFF1877F2)), // Фирменный синий цвет Facebook
                label: 'Continue with Facebook',
                onPressed: () {},
              ),
              const SizedBox(height: 32),

              // Разделитель "OR"
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppTheme.cardSlate.withOpacity(0.5), thickness: 1),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: TextStyle(color: AppTheme.textLightGrey, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppTheme.cardSlate.withOpacity(0.5), thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Кнопка "Continue with email" (В новом стальном стиле)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.cardSlate,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Овальная форма
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // Переход на экран логина
                  context.push('/login');
                },
                child: const Text(
                  'Continue with email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Кастомный виджет для кнопок соцсетей
  Widget _buildSocialButton({
    required Widget iconWidget,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cardSlate, // Тот самый стальной цвет
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            // Иконка слева
            SizedBox(width: 30, child: iconWidget),

            // Текст строго по центру
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Невидимая заглушка справа для идеального баланса текста по центру
            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }

  // Временная заглушка для иконки Google
  // (Потом можно будет скачать картинку google.png и использовать Image.asset)
  Widget _buildGooglePlaceholder() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'San Francisco', // Или любой другой базовый шрифт
          ),
        ),
      ),
    );
  }
}
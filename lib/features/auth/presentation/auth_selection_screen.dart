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

              // Логотип
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentYellow, width: 3),
                ),
                child: const Center(
                  child: Icon(Icons.terrain_rounded, size: 40, color: AppTheme.accentYellow),
                ),
              ),
              const SizedBox(height: 32),

              // Заголовок
              const Text(
                'Sign up log in to start exploring',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),

              // Кнопки соцсетей
              _buildSocialButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              _buildSocialButton(
                icon: Icons.email,
                label: 'Continue with Google',
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              _buildSocialButton(
                icon: Icons.facebook,
                label: 'Continue with Facebook',
                onPressed: () {},
              ),
              const SizedBox(height: 40),

              // Разделитель "OR"
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Кнопка "Continue with email" (Белая)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  // Переход на экран регистрации
                  context.push('/login');
                },
                child: const Text(
                  'Continue with email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Кастомный виджет для соц. кнопки
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    double iconSize = 24,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentYellow,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            // Иконка слева
            Icon(icon, size: iconSize, color: Colors.white),

            // Текст строго по центру
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Невидимая заглушка справа для баланса, чтобы текст был идеально по центру
            SizedBox(width: iconSize),
          ],
        ),
      ),
    );
  }
}
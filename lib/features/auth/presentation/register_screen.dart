// lib/features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/locator.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = locator<AuthProvider>();

      await authProvider.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при регистрации. Проверьте данные.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark, // Темный фон из нашей темы
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Иконка вместо скучного заголовка
              const Center(
                child: Icon(Icons.person_add_alt_1_rounded, size: 60, color: AppTheme.accentYellow),
              ),
              const SizedBox(height: 24),

              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),

              const Text(
                'Sign up to track your first trail',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Поля ввода с кастомным стилем
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _customInputDecoration('Username', Icons.person_outline),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _customInputDecoration('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: _customInputDecoration('Password', Icons.lock_outline),
              ),
              const SizedBox(height: 40),

              // Кнопка в стиле дизайна
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _isLoading ? null : _onRegister,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 24),

              // Текст для перехода на логин
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppTheme.textGrey)),
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: const Text(
                      'Log In',
                      style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper-метод для красивых текстовых полей
  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textGrey),
      prefixIcon: Icon(icon, color: AppTheme.textGrey),
      filled: true,
      fillColor: AppTheme.cardDark, // Цвет заливки инпута
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none, // Убираем стандартную рамку
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.accentYellow, width: 2), // Золотая рамка при фокусе
      ),
      floatingLabelStyle: const TextStyle(color: AppTheme.accentYellow), // Цвет текста при поднятии
    );
  }
}
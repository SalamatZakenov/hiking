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
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = locator<AuthProvider>();

      final bool isSuccess = await authProvider.register(
        username: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Регистрация прошла успешно!'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/login');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка регистрации. Возможно, email уже занят.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сети: $e'),
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
      backgroundColor: AppTheme.bgDark, // Новый глубокий фон
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Премиальная иконка в стиле нового дизайна
              Center(
                child: Container(
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
                    child: const Icon(Icons.person_add_rounded, size: 36, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),

              const Text(
                'Sign up to track your first trail',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLightGrey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Поля ввода с новым "стальным" стилем
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _customInputDecoration('Username', Icons.person_outline_rounded),
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
                decoration: _customInputDecoration('Password', Icons.lock_outline_rounded),
              ),
              const SizedBox(height: 40),

              // Кнопка регистрации
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.cardSlate, // Стальной цвет
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _isLoading ? null : _onRegister,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 32),

              // Текст для перехода на логин
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppTheme.textLightGrey)),
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: const Text(
                      'Log In',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  // Обновленный helper-метод для красивых текстовых полей
  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textLightGrey),
      prefixIcon: Icon(icon, color: AppTheme.textLightGrey),
      filled: true,
      fillColor: AppTheme.iconDark, // Новый темно-синий цвет заливки инпута
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20), // Более скругленные углы
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppTheme.cardSlate, width: 2), // Стальная рамка при фокусе
      ),
      floatingLabelStyle: const TextStyle(color: AppTheme.textLightGrey),
    );
  }
}
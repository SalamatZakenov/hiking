// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final AuthProvider authProvider;

  const LoginScreen({super.key, required this.authProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      await widget.authProvider.login(
        _emailController.text,
        _passwordController.text,
      );
      // Если успешно, GoRouter сам перекинет нас на карту
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка входа. Проверьте email и пароль.'),
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
      backgroundColor: AppTheme.bgDark, // Фирменный глубокий фон
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(), // Возврат на Auth Selection
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Премиальная иконка (как на экране регистрации)
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
                    child: const Icon(Icons.landscape_rounded, size: 36, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),

              const Text(
                'Log in to continue exploring',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textLightGrey, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Поле Email
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _customInputDecoration('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              // Поле Password
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: _customInputDecoration('Password', Icons.lock_outline_rounded),
              ),
              const SizedBox(height: 40),

              // Кнопка логина (стальной стиль)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.cardSlate,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 32),

              // Переход на регистрацию
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppTheme.textLightGrey)),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text(
                      'Sign Up',
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

  // Обновленный стиль для полей ввода (один в один как в RegisterScreen)
  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textLightGrey),
      prefixIcon: Icon(icon, color: AppTheme.textLightGrey),
      filled: true,
      fillColor: AppTheme.iconDark, // Темно-синяя заливка
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppTheme.cardSlate, width: 2), // Стальная рамка
      ),
      floatingLabelStyle: const TextStyle(color: AppTheme.textLightGrey),
    );
  }
}
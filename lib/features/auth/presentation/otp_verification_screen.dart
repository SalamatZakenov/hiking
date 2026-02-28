// lib/features/auth/presentation/otp_verification_screen.dart
import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final AuthProvider authProvider;

  const OtpVerificationScreen({super.key, required this.email, required this.authProvider});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length < 4) return;

    setState(() => _isLoading = true);

    // Имитация задержки сети проверки кода
    await Future.delayed(const Duration(seconds: 1));

    // Имитируем успешный вход.
    // GoRouter заметит изменение стейта и перекинет нас на /map
    await widget.authProvider.login(widget.email, 'dummy_password');

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Проверьте почту',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Мы отправили 4-значный код на\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Поле ввода кода с увеличенным расстоянием между буквами (Letter Spacing)
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, letterSpacing: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '0000',
                  hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  // Автоматически запускаем проверку, если ввели 4 цифры
                  if (value.length == 4) {
                    _verifyCode();
                  }
                },
              ),
              const Spacer(),

              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Подтвердить', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {}, // Заглушка для отправки повторного письма
                child: const Text('Отправить код еще раз', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
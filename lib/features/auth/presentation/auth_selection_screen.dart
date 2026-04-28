// lib/features/auth/presentation/auth_selection_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AuthSelectionScreen extends StatefulWidget {
  final AuthProvider authProvider;
  const AuthSelectionScreen({super.key, required this.authProvider});

  @override
  State<AuthSelectionScreen> createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. ДЛЯ iOS: Проверяем ссылку, если приложение "просыпается"
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      debugPrint('Ошибка стартовой ссылки: $e');
    }

    // 2. Слушаем ссылки в реальном времени
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme == 'shynapp' && uri.host == 'login-callback') {
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];

      if (token != null) {
        debugPrint('УСПЕШНЫЙ ВХОД! Токен: $token');

        // Даем iOS полсекунды на плавное закрытие Safari, прежде чем дергать Роутер
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            widget.authProvider.loginWithOAuthToken(token);
          }
        });

      } else if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $error')));
        }
      }
    }
  }

  // Метод запуска OAuth
  Future<void> _launchOAuthUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2), // Отступ сверху до текста

              // --- ЗАГОЛОВОК ---
              const Text(
                'Sign up log in to\nstart exploring',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 2), // Отступ от текста до кнопок

              // --- КНОПКА FACEBOOK ---
              _buildSocialButton(
                iconWidget: Image.asset('assets/facebook_logo.png', height: 26, width: 26),
                label: 'Continue with Facebook',
                onPressed: () => _launchOAuthUrl('https://shyn-api.site/oauth2/authorization/facebook'),
              ),
              const SizedBox(height: 16),

              // --- КНОПКА GOOGLE (Светло-серая как на референсе) ---
              _buildSocialButton(
                iconWidget: Image.asset('assets/google_logo.png', height: 26, width: 26),
                label: 'Continue with Google',
                backgroundColor: const Color(0xFF9CA3AF), // Светло-серый/стальной цвет
                textColor: Colors.white,
                onPressed: () => _launchOAuthUrl('https://shyn-api.site/oauth2/authorization/google'),
              ),

              const SizedBox(height: 40),

              // --- РАЗДЕЛИТЕЛЬ "OR" ---
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('OR', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13))
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1)),
                ],
              ),

              const SizedBox(height: 40),

              // --- КНОПКА EMAIL ---
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.cardSlate,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: () => context.push('/login'),
                child: const Text('Continue with email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),

              const Spacer(flex: 3), // Отступ снизу
            ],
          ),
        ),
      ),
    );
  }

  // Обновленный метод создания кнопки: иконка строго слева, текст строго по центру
  Widget _buildSocialButton({
    required Widget iconWidget,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.cardSlate,
          foregroundColor: textColor ?? Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: onPressed,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Иконка прижата к левому краю
            Align(
              alignment: Alignment.centerLeft,
              child: iconWidget,
            ),
            // Текст ровно по центру кнопки
            Text(
                label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.white
                )
            ),
          ],
        ),
      ),
    );
  }
}
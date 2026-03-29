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


  // Обновленный метод запуска
  Future<void> _launchOAuthUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(
      url,
      // ВЕРНУЛИ ВНЕШНИЙ БРАУЗЕР! Он работает на 100% безотказно.
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
              const SizedBox(height: 60),

              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: AppTheme.iconDark, shape: BoxShape.circle, border: Border.all(color: AppTheme.cardSlate.withOpacity(0.5), width: 4)),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.cardSlate, width: 2), shape: BoxShape.circle),
                  child: const Icon(Icons.terrain_rounded, size: 36, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),

              const Text('Sign up log in to start exploring', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 48),

              _buildSocialButton(
                iconWidget: const Icon(Icons.apple, size: 28, color: Colors.white),
                label: 'Continue with Apple',
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              _buildSocialButton(
                iconWidget: _buildGooglePlaceholder(),
                label: 'Continue with Google',
                onPressed: () => _launchOAuthUrl('https://shyn-api.site/oauth2/authorization/google'),
              ),
              const SizedBox(height: 16),

              _buildSocialButton(
                iconWidget: const Icon(Icons.facebook, size: 28, color: Color(0xFF1877F2)),
                label: 'Continue with Facebook',
                onPressed: () => _launchOAuthUrl('https://shyn-api.site/oauth2/authorization/facebook'),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.cardSlate.withOpacity(0.5), thickness: 1)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('OR', style: TextStyle(color: AppTheme.textLightGrey, fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Divider(color: AppTheme.cardSlate.withOpacity(0.5), thickness: 1)),
                ],
              ),
              const SizedBox(height: 32),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.cardSlate, foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0,
                ),
                onPressed: () => context.push('/login'),
                child: const Text('Continue with email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required Widget iconWidget, required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cardSlate, foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            SizedBox(width: 30, child: iconWidget),
            Expanded(child: Center(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGooglePlaceholder() {
    return Container(
      width: 24, height: 24,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Center(child: Text('G', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'San Francisco'))),
    );
  }
}
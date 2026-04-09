// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'core/di/locator.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/routes/providers/route_provider.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'features/tracking/providers/tracking_provider.dart';

void main() async {
  // Обязательно вызываем это первыми
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем locator (твои зависимости)
  setupLocator();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // --- МАГИЯ СОХРАНЕНИЯ СЕССИИ ---
  // Получаем AuthProvider из локатора и проверяем память телефона
  final authProvider = locator<AuthProvider>();
  await authProvider.checkAuthStatus();

  runApp(
    // Используем MultiProvider для подключения нескольких провайдеров
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: authProvider, // Передаем провайдер, который уже проверил память!
        ),
        ChangeNotifierProvider.value(
          value: locator<TrackingProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => RouteProvider()..loadRoutes(),
        ),
      ],
      child: const HikingApp(),
    ),
  );
}

class HikingApp extends StatelessWidget {
  const HikingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final router = AppRouter.createRouter(authProvider);

    return MaterialApp.router(
      title: 'Hiking MVP',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
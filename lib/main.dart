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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(
    // Используем MultiProvider для подключения нескольких провайдеров
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: locator<AuthProvider>(),
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
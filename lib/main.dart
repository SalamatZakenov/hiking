// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Не забудь импорт!

// Относительные импорты
import 'core/di/locator.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем зависимости (GetIt)
  setupLocator();

  runApp(
    // Оборачиваем всё приложение, используя экземпляр из локатора
    ChangeNotifierProvider.value(
      value: locator<AuthProvider>(),
      child: const HikingApp(),
    ),
  );
}

class HikingApp extends StatelessWidget {
  const HikingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Теперь мы можем достать провайдер через контекст
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
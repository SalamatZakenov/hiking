import 'package:flutter/material.dart';

// Относительные импорты
import 'core/di/locator.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем зависимости до запуска UI
  setupLocator();

  // Вызываем без параметров! Вся магия теперь внутри через DI
  runApp(const HikingApp());
}

class HikingApp extends StatelessWidget {
  const HikingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем authProvider из локатора
    final authProvider = locator<AuthProvider>();

    // Передаем его роутеру
    final router = AppRouter.createRouter(authProvider);

    return MaterialApp.router(
      title: 'Hiking MVP',

      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
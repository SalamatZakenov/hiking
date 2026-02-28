// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/routes/presentation/routes_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/map',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;

        // Список путей, доступных БЕЗ авторизации
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/verify-email';

        // Если не авторизован и пытается зайти в закрытую часть -> на логин
        if (!isLoggedIn && !isAuthRoute) return '/login';

        // Если авторизован и пытается зайти на экраны логина/регистрации -> на карту
        if (isLoggedIn && isAuthRoute) return '/map';

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(authProvider: authProvider),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) {
            // Передаем email из предыдущего экрана для красивого UI
            final email = state.extra as String? ?? 'вашу почту';
            return OtpVerificationScreen(
              email: email,
              authProvider: authProvider,
            );
          },
        ),
        // ... остальной код StatefulShellRoute без изменений
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return DashboardScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/map', builder: (context, state) => const MapScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/routes', builder: (context, state) => const RoutesScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => ProfileScreen(authProvider: authProvider))]),
          ],
        ),
      ],
    );
  }
}
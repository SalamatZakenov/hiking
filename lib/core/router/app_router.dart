// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/routes/presentation/routes_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/map',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;

        // Разрешенные экраны без авторизации
        final isAuthRoute = state.matchedLocation == '/onboarding' ||
            state.matchedLocation == '/auth-selection' || // Будущий экран
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // Если не авторизован и лезет на карту -> кидаем на онбординг
        if (!isLoggedIn && !isAuthRoute) return '/onboarding';

        // Если авторизован и находится на экранах входа -> кидаем на карту
        if (isLoggedIn && isAuthRoute) return '/map';

        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        // ... (остальные твои роуты: /login, /register, StatefulShellRoute)
        GoRoute(
          path: '/auth-selection',
          builder: (context, state) => const AuthSelectionScreen(),
        ),
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
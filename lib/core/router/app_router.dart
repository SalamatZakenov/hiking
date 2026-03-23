import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/auth_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/routes/presentation/routes_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/routes/presentation/route_details_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/routes',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/onboarding' ||
            state.matchedLocation == '/auth-selection' ||
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isLoggedIn && !isAuthRoute) return '/onboarding';
        if (isLoggedIn && isAuthRoute) return '/routes';
        return null;
      },
      routes: [
        // --- ЭКРАНЫ БЕЗ НИЖНЕЙ ПАНЕЛИ НАВИГАЦИИ ---
        GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
        GoRoute(path: '/auth-selection', builder: (context, state) => const AuthSelectionScreen()),
        GoRoute(path: '/login', builder: (context, state) => LoginScreen(authProvider: authProvider)),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

        // --- ЭКРАНЫ С НИЖНЕЙ ПАНЕЛЬЮ НАВИГАЦИИ (5 ВЕТОК) ---
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => DashboardScreen(navigationShell: navigationShell),
          branches: [

            // 0. Ветка HOME (Routes)
            StatefulShellBranch(
                routes: [
                  GoRoute(
                      path: '/routes',
                      builder: (context, state) => const RoutesScreen(),
                      routes: [
                        // Вложенный роут: /routes/123 (Детали маршрута)
                        GoRoute(
                          path: ':id',
                          builder: (context, state) {
                            final routeId = state.pathParameters['id']!;
                            return RouteDetailsScreen(routeId: routeId);
                          },
                        ),
                      ]
                  )
                ]
            ),

            // 1. Ветка COMMUNITY (Заглушка)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/community',
                  builder: (context, state) => const Scaffold(
                    backgroundColor: AppTheme.bgDark,
                    body: Center(
                      child: Text('Community Hub\nComing Soon', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.cardSlate, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Ветка MAPS (Реальная карта)
            // В DashboardScreen мы прописали скрытие панели именно для индекса 2!
            StatefulShellBranch(
                routes: [
                  GoRoute(
                      path: '/map',
                      builder: (context, state) => const MapScreen()
                  )
                ]
            ),

            // 3. Ветка LIKE (Заглушка)
            StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/liked',
                    builder: (context, state) => const Scaffold(
                      backgroundColor: AppTheme.bgDark,
                      body: Center(
                        child: Text('Liked Routes\nComing Soon', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.cardSlate, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ]
            ),

            // 4. Ветка PROFILE
            StatefulShellBranch(
                routes: [
                  GoRoute(
                      path: '/profile',
                      builder: (context, state) => const ProfileScreen()
                  )
                ]
            ),

          ],
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/map/presentation/map_screen.dart';
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
        GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
        GoRoute(path: '/auth-selection', builder: (context, state) => const AuthSelectionScreen()),
        GoRoute(path: '/login', builder: (context, state) => LoginScreen(authProvider: authProvider)),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => DashboardScreen(navigationShell: navigationShell),
          branches: [
            // Ветка Explore/Map
            StatefulShellBranch(
                routes: [
                  GoRoute(
                      path: '/routes',
                      builder: (context, state) => const RoutesScreen(),
                      routes: [
                        // Вложенный роут: /routes/123
                        GoRoute(
                          path: ':id',
                          builder: (context, state) {
                            final routeId = state.pathParameters['id']!;
                            return RouteDetailsScreen(routeId: routeId); // Не забудь импортировать RouteDetailsScreen вверху!
                          },
                        ),
                      ]
                  )
                ]
            ),

            // 2. Map (реальная карта)
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/map',
                  builder: (context, state) => const MapScreen()
              )
            ]
            ),

            // 3. Like (пустая заглушка)
            StatefulShellBranch(routes: [
              GoRoute(path: '/liked', builder: (context, state) => const Scaffold(backgroundColor: AppTheme.bgDark, body: Center(child: Text('Liked Routes', style: TextStyle(color: Colors.white)))))
            ]),

            // 4. Profile
            StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())]),
          ],
        ),
      ],
    );
  }
}
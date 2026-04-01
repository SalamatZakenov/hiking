// lib/core/router/app_router.dart
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
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
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
        // --- ЭКРАНЫ БЕЗ НИЖНЕЙ ПАНЕЛИ ---
        GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
        GoRoute(path: '/auth-selection', builder: (context, state) => AuthSelectionScreen(authProvider: authProvider)),
        GoRoute(path: '/login', builder: (context, state) => LoginScreen(authProvider: authProvider)),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

        // --- ДЕТАЛЬНЫЙ ЭКРАН МАРШРУТА ПОВЕРХ ВСЕГО ---
        GoRoute(
          path: '/routes/:id', // ВЫНЕСЛИ СЮДА!
          parentNavigatorKey: _rootNavigatorKey, // Открывается поверх нижней панели
          builder: (context, state) {
            final routeId = state.pathParameters['id']!;
            return RouteDetailsScreen(routeId: routeId);
          },
        ),

        // --- КАРТА ---
        GoRoute(
          path: '/map',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final targetPeakName = state.extra as String?;

            return CustomTransitionPage(
              key: state.pageKey,
              child: MapScreen(targetPeakName: targetPeakName),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
              transitionDuration: const Duration(milliseconds: 350),
            );
          },
        ),

        // --- ЭКРАНЫ С НИЖНЕЙ ПАНЕЛЬЮ НАВИГАЦИИ ---
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => DashboardScreen(navigationShell: navigationShell),
          branches: [
            // 0. Ветка HOME
            StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/routes',
                    builder: (context, state) => const RoutesScreen(),
                  )
                ]
            ),

            // 1. Ветка COMMUNITY
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/community',
                  builder: (context, state) => const Scaffold(
                    backgroundColor: AppTheme.bgDark,
                    body: Center(child: Text('Community Hub\nComing Soon', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.cardSlate, fontSize: 24, fontWeight: FontWeight.bold))),
                  ),
                ),
              ],
            ),

            // 2. Ветка MAPS (Пустая заглушка)
            StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/map-tab',
                    builder: (context, state) => const SizedBox(),
                  )
                ]
            ),

            // 3. Ветка LIKED
            StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/liked',
                    builder: (context, state) => const Scaffold(
                      backgroundColor: AppTheme.bgDark,
                      body: Center(child: Text('Liked Routes\nComing Soon', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.cardSlate, fontSize: 24, fontWeight: FontWeight.bold))),
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
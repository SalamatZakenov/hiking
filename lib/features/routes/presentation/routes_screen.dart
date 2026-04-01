// lib/features/routes/presentation/routes_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/route_provider.dart';
import '../data/models/route_model.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);

    final String userName = (authProvider.user?.username ?? 'EXPLORER').toUpperCase();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // --- 1. ШАПКА ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('SHYN', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Уведомлений пока нет')));
                          }
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. СКРОЛЛИРУЕМАЯ ЧАСТЬ ---
              Expanded(
                child: RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: AppTheme.cardSlate,
                  onRefresh: () async => await routeProvider.loadRoutes(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text('MORNING, $userName', style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        const Text('Discover the\ngreat outdoors.', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.5)),
                        const SizedBox(height: 32),

                        // --- ЖИВОЙ ПОИСК И ФИЛЬТР ---
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                                child: Row(children: [
                                  const Icon(Icons.search_rounded, color: Colors.white54, size: 28),
                                  const SizedBox(width: 12),
                                  // Сделали настоящий TextField вместо обычного текста
                                  Expanded(
                                    child: TextField(
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                      decoration: InputDecoration(
                                        hintText: 'Search parks, peaks...',
                                        hintStyle: TextStyle(color: Colors.white54.withOpacity(0.5), fontSize: 16),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 56, width: 56, decoration: BoxDecoration(color: AppTheme.cardSlate, borderRadius: BorderRadius.circular(16)),
                              child: IconButton(
                                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фильтры скоро появятся!')));
                                  }
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- СПИСОК МАРШРУТОВ ИЗ БАЗЫ ---
                        if (routeProvider.isLoading && routeProvider.routes.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Colors.white)))
                        else if (routeProvider.error != null && routeProvider.routes.isEmpty)
                          Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(routeProvider.error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                              )
                          )
                        else if (routeProvider.routes.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No routes found.', style: TextStyle(color: Colors.white54))))
                          else
                            ...routeProvider.routes.map((route) {
                              return GestureDetector(
                                onTap: () => context.push('/routes/${route.id}'), // Открываем детальный экран свайпом!
                                behavior: HitTestBehavior.opaque,
                                child: RouteCardLive(route: route),
                              );
                            }),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Карточка маршрута
class RouteCardLive extends StatelessWidget {
  final RouteModel route;

  const RouteCardLive({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 280,
      decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Stack(
        children: [
          // Картинка с бэкенда
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                route.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.terrain_rounded, size: 80, color: Colors.white10)),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white24));
                },
              ),
            ),
          ),

          // Плашка с информацией снизу
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24), top: Radius.circular(16)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(route.location.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Text(route.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${route.distance} km', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          _buildDifficultyBadge(route.difficulty),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- УБРАЛИ ЗВЕЗДОЧКИ ---
  Widget _buildDifficultyBadge(String difficulty) {
    Color badgeColor;
    switch (difficulty.toUpperCase()) {
      case 'HARD': badgeColor = const Color(0xFFFF5252); break;
      case 'EASY': badgeColor = const Color(0xFF4CAF50); break;
      case 'MEDIUM': badgeColor = const Color(0xFFFF9F0A); break;
      default: badgeColor = const Color(0xFFFFC107);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Немного увеличил отступы по бокам
      decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: badgeColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Text(
          difficulty.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)
      ),
    );
  }
}
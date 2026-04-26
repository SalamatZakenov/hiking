// lib/features/routes/presentation/routes_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/route_provider.dart';
import '../data/models/route_model.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: const Color(0xFF32D74B),
            backgroundColor: Colors.black,
            onRefresh: () => routeProvider.fetchRoutes(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // --- 1 & 2. ПЛАВАЮЩАЯ ШАПКА И ПОИСК ---
                SliverAppBar(
                  backgroundColor: Colors.black,
                  floating: true,
                  snap: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  toolbarHeight: 70,

                  title: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.filter_hdr_rounded, color: Color(0xFF32D74B), size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'SHYN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                        )
                      ],
                    ),
                  ),

                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(96),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Search routes...',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 18),
                                ),
                                onChanged: (val) => routeProvider.searchRoutes(val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.tune_rounded, color: Colors.white),
                              onPressed: () { HapticFeedback.lightImpact(); },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // --- 3. СПИСОК МАРШРУТОВ ---
                if (routeProvider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF32D74B))),
                  )
                else if (routeProvider.filteredRoutes.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No routes found.', style: TextStyle(color: Colors.white54))),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final route = routeProvider.filteredRoutes[index];
                          return _buildPremiumRouteCard(context, route);
                        },
                        childCount: routeProvider.filteredRoutes.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ОБНОВЛЕННАЯ КАРТОЧКА: GLASS МОЛОЧНЫЙ СТИЛЬ ---
  Widget _buildPremiumRouteCard(BuildContext context, RouteModel route) {
    final String distanceStr = route.calculatedDistance != null
        ? '${route.calculatedDistance!.toStringAsFixed(1)} KM'
        : '-- KM';

    return GestureDetector(
      onTap: () => context.push('/routes/${route.id}'),
      child: Container(
        height: 280, // Вернули стандартную высоту, так как панель стала меньше
        margin: const EdgeInsets.only(bottom: 24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. КАРТИНКА (ФОН)
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: CachedNetworkImage(
                imageUrl: route.imageUrls.isNotEmpty ? route.imageUrls.first : 'https://via.placeholder.com/600x400',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF32D74B))),
                ),
              ),
            ),

            // 2. СЛОЖНОСТЬ (СВЕРХУ СЛЕВА)
            Positioned(
              top: 16, left: 16,
              child: _buildDifficultyBadge(route.difficulty),
            ),

            // 3. РЕЙТИНГ (СВЕРХУ СПРАВА)
            Positioned(
              top: 16, right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(route.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. НИЖНЯЯ ПАНЕЛЬ: ULTRA-GLASS (КОМПАКТНАЯ)
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ЛОКАЦИЯ (Верхняя строчка)
                        Text(
                          route.location.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),

                        // НАЗВАНИЕ + ДИСТАНЦИЯ (В одну строку)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                route.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22, // Чуть уменьшили, чтобы всё влезло
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // ДИСТАНЦИЯ ТЕПЕРЬ СПРАВА
                            Text(
                              distanceStr,
                              style: const TextStyle(
                                color: Color(0xFF32D74B),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
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
      ),
    );
  }

  // Стили бейджиков сложности как на скрине (светлый фон + яркий текст)
  Widget _buildDifficultyBadge(String difficulty) {
    Color bgColor;
    Color textColor;

    switch (difficulty.toUpperCase()) {
      case 'HARD':
        bgColor = const Color(0xFFFFEBEB);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'EASY':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'MEDIUM':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      default:
        bgColor = Colors.white.withOpacity(0.1);
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
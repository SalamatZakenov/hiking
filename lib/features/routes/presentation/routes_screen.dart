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
import '../../../core/widgets/custom_header.dart';

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
                SliverAppBar(
                  backgroundColor: Colors.black,
                  floating: true,
                  snap: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  toolbarHeight: 80, // ЕДИНАЯ ВЫСОТА
                  title: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24), // ЕДИНЫЙ ОТСТУП
                    child: CustomHeader(title: 'ROUTES'),
                  ),
                  // КОМПАКТНЫЙ ПОИСК + ФИЛЬТР
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60), // Высота как в Community
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44, // Компактный размер
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16)
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Search routes...',
                                  hintStyle: TextStyle(color: Colors.white54, fontSize: 15),
                                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white54, size: 22),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (val) => routeProvider.searchRoutes(val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // КНОПКА ФИЛЬТРА (тоже 44x44)
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16)
                            ),
                            child: IconButton(
                                icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                                onPressed: () { HapticFeedback.lightImpact(); }
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (routeProvider.isLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF32D74B))))
                else if (routeProvider.filteredRoutes.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('No routes found.', style: TextStyle(color: Colors.white54))))
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
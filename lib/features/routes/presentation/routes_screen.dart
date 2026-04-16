// lib/features/routes/presentation/routes_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
        backgroundColor: Colors.black, // Единый черный фон
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
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF32D74B).withOpacity(0.2),
                        child: Text(userName[0], style: const TextStyle(color: Color(0xFF32D74B), fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),

              // --- 2. ПОИСК ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05), // Единый цвет карточек
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search routes...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (val) => routeProvider.searchRoutes(val),
                  ),
                ),
              ),

              // --- 3. ФИЛЬТРЫ КАТЕГОРИЙ ---
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: routeProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = routeProvider.categories[index];
                    final isSelected = routeProvider.selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => routeProvider.selectCategory(category),
                        selectedColor: const Color(0xFF32D74B), // Неоновый зеленый
                        backgroundColor: Colors.white.withOpacity(0.05),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // --- 4. СПИСОК МАРШРУТОВ ---
              Expanded(
                child: routeProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF32D74B)))
                    : routeProvider.filteredRoutes.isEmpty
                    ? const Center(child: Text('No routes found.', style: TextStyle(color: Colors.white54)))
                    : RefreshIndicator(
                  color: const Color(0xFF32D74B),
                  backgroundColor: Colors.black,
                  onRefresh: () => routeProvider.fetchRoutes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                    itemCount: routeProvider.filteredRoutes.length,
                    itemBuilder: (context, index) {
                      final route = routeProvider.filteredRoutes[index];
                      return _buildRouteCard(context, route);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, RouteModel route) {
    return GestureDetector(
      onTap: () => context.push('/routes/${route.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05), // Единый стиль карточек
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка с бейджиком лайка
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    route.imageUrls.isNotEmpty ? route.imageUrls.first : 'https://via.placeholder.com/400x200',
                    height: 180, width: double.infinity, fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.bookmark_border, color: Color(0xFF32D74B), size: 20),
                  ),
                ),
              ],
            ),

            // Информация
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(route.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(route.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF32D74B), size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(route.location, style: const TextStyle(color: Colors.white54, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route_rounded, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Text(
                              route.calculatedDistance != null ? '${route.calculatedDistance!.toStringAsFixed(1)} km' : '? km',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)
                          ),
                          const SizedBox(width: 12),
                          _buildDifficultyBadge(route.difficulty),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Обновленный бейджик без теней, в стиле Activity Feed
  Widget _buildDifficultyBadge(String difficulty) {
    Color badgeColor;
    switch (difficulty.toUpperCase()) {
      case 'HARD': badgeColor = const Color(0xFFFF5252); break;
      case 'EASY': badgeColor = const Color(0xFF4CAF50); break;
      case 'MEDIUM': badgeColor = const Color(0xFFFF9F0A); break;
      default: badgeColor = const Color(0xFFFFC107);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(difficulty.toUpperCase(), style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
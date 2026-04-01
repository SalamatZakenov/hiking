// lib/features/routes/presentation/route_details_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/route_provider.dart';
import '../data/models/route_model.dart';
import '../../../core/theme/app_theme.dart';

class RouteDetailsScreen extends StatelessWidget {
  final String routeId;

  const RouteDetailsScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    // Получаем список маршрутов из нашего провайдера
    final routeProvider = Provider.of<RouteProvider>(context);

    // Ищем нужный маршрут по ID
    // Так как routeId из URL это String, а в модели int, делаем toString()
    RouteModel? route;
    try {
      route = routeProvider.routes.firstWhere((r) => r.id.toString() == routeId);
    } catch (e) {
      route = null;
    }

    // Если маршрут не найден (например, ошибка загрузки)
    if (route == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Route not found', style: TextStyle(color: Colors.white))),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Stack(
          children: [
            // --- 1. ФОНОВАЯ КАРТИНКА ИЗ БЭКЕНДА ---
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).size.height * 0.55,
              child: Image.network(
                route.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF2C2C2E), child: const Center(child: Icon(Icons.terrain_rounded, size: 80, color: Colors.white10))),
              ),
            ),
            // Градиент для плавного перехода
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).size.height * 0.55,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent, AppTheme.bgDark],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // --- 2. КНОПКА "НАЗАД" ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassIconButton(Icons.arrow_back_ios_new_rounded, () => context.pop()),
                    _buildGlassIconButton(Icons.favorite_border_rounded, () {}),
                  ],
                ),
              ),
            ),

            // --- 3. ИНФОРМАЦИЯ О МАРШРУТЕ ---
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.55,
                decoration: const BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Бейджики: Категория и Сложность
                      Row(
                        children: [
                          _buildBadge(route.category.toUpperCase(), Colors.blueAccent),
                          const SizedBox(width: 8),
                          _buildBadge(route.difficulty.toUpperCase(), _getDifficultyColor(route.difficulty)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Название и локация
                      Text(route.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppTheme.cardSlate, size: 18),
                          const SizedBox(width: 6),
                          Expanded(child: Text(route.location, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500))),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Статистика (Дистанция и Координаты)
                      Row(
                        children: [
                          _buildStatCard(Icons.route_rounded, '${route.distance} km', 'Distance'),
                          const SizedBox(width: 16),
                          _buildStatCard(Icons.explore_rounded, '${route.latitude.toStringAsFixed(2)}, ${route.longitude.toStringAsFixed(2)}', 'Coordinates'),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Описание (пока заглушка, если бэк не отдает поле desc)
                      const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      const Text(
                        'A beautiful trail that challenges your stamina but rewards you with breathtaking views. Make sure to bring enough water and wear proper hiking boots.',
                        style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                      ),
                      const SizedBox(height: 40),

                      // --- 4. КНОПКА "ОТКРЫТЬ НА КАРТЕ" ---
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            // Пока передаем имя пика, потом переделаем MapScreen под координаты
                            context.push('/map', extra: '${route!.name}||${route.latitude},${route.longitude}');
                          },
                          child: const Text('View on Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ПОМОЩНИКИ ---
  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toUpperCase()) {
      case 'HARD': return const Color(0xFFFF5252);
      case 'MEDIUM': return const Color(0xFFFF9F0A);
      case 'EASY': return const Color(0xFF4CAF50);
      default: return Colors.grey;
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
    );
  }

  Widget _buildStatCard(IconData icon, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.cardSlate, size: 28),
            const SizedBox(height: 12),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
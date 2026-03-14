// lib/features/routes/presentation/route_details_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/locator.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/repositories/route_repository_interface.dart';
import '../../../shared/models/route_model.dart';

class RouteDetailsScreen extends StatefulWidget {
  final String routeId;

  const RouteDetailsScreen({super.key, required this.routeId});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final IRouteRepository _repository = locator<IRouteRepository>();
  late Future<HikingRoute?> _routeFuture;

  @override
  void initState() {
    super.initState();
    // Ищем маршрут по ID, который передали при нажатии
    _routeFuture = _repository.getRouteById(widget.routeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: FutureBuilder<HikingRoute?>(
        future: _routeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow));
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Маршрут не найден', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  )
                ],
              ),
            );
          }

          final route = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // Тот самый параллакс-заголовок
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                backgroundColor: AppTheme.bgDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
                    onPressed: () {}, // Добавление в избранное
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Заглушка для фото или 3D карты горы
                      Container(color: AppTheme.cardDark),
                      const Center(
                        child: Icon(Icons.landscape_rounded, size: 100, color: Colors.white12),
                      ),
                      // Градиент для плавного перехода в темный фон
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.bgDark],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Основной контент (скроллится под заголовок)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Категория (Пик, Парк и т.д.)
                      Text(
                        route.category.toUpperCase(),
                        style: const TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      // Название
                      Text(
                        route.name,
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Локация
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.textGrey, size: 18),
                          const SizedBox(width: 8),
                          Text(route.location, style: const TextStyle(color: AppTheme.textGrey, fontSize: 16)),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Блок статистики (Сложность, Дистанция, Время)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatBox(Icons.trending_up_rounded, 'Difficulty', route.difficulty),
                          _buildStatBox(Icons.route_outlined, 'Distance', '${route.lengthKm} km'),
                          _buildStatBox(Icons.timer_outlined, 'Est. Time', '4-5 hrs'), // Пока хардкод
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Описание
                      const Text(
                        'Description',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This is a beautiful trail located in the heart of the mountains. It offers stunning panoramic views, challenging ascents, and a rewarding summit experience. Make sure to bring plenty of water and wear proper hiking shoes.',
                        style: TextStyle(color: AppTheme.textGrey, height: 1.5, fontSize: 16),
                      ),

                      const SizedBox(height: 100), // Отступ для нижней кнопки
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Фиксированная кнопка внизу "Начать маршрут"
      bottomSheet: Container(
        color: AppTheme.bgDark,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentYellow,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          onPressed: () {},
          child: const Text('Start Navigation', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accentYellow, size: 28),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
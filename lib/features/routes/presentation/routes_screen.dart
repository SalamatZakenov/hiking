// lib/features/routes/presentation/routes_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/repositories/route_repository_interface.dart';
import '../../../shared/models/route_model.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final IRouteRepository _repository = locator<IRouteRepository>();
  late Future<List<HikingRoute>> _routesFuture;

  // Индекс выбранной категории (0 - Hiking, 1 - Camping, 2 - Climbing)
  int _selectedCategoryIndex = 1;

  @override
  void initState() {
    super.initState();
    _routesFuture = _repository.getRoutes();
  }

  @override
  Widget build(BuildContext context) {
    // Получаем пользователя для отображения имени
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 1. Верхний блок: Аватар, Приветствие, Уведомления
            _buildHeader(context, user),

            const SizedBox(height: 24),

            // 2. Поисковая строка
            _buildSearchBar(),

            const SizedBox(height: 24),

            // 3. Фильтры/Категории
            _buildCategories(),

            const SizedBox(height: 24),

            // 4. Список маршрутов (оставшаяся часть экрана)
            Expanded(
              child: FutureBuilder<List<HikingRoute>>(
                future: _routesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Ошибка: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Маршруты не найдены', style: TextStyle(color: AppTheme.textGrey)));
                  }

                  final routes = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      return RouteCard(route: route);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Компоненты UI ---

  Widget _buildHeader(BuildContext context, User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Аватар
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.cardDark,
            child: Text(
              user?.username.substring(0, 1).toUpperCase() ?? 'Y',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),

          // Текст приветствия
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.go('/profile'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome Back ✋', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                  Text(
                    user?.username ?? 'user',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Иконка уведомлений (ТЕПЕРЬ КЛИКАБЕЛЬНАЯ)
          GestureDetector(
            onTap: () => _showNotificationsPanel(context), // Вызов шторки
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.bgDark, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.textGrey, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search trails..',
                  hintStyle: TextStyle(color: AppTheme.textGrey.withOpacity(0.5), fontSize: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.terrain, 'title': 'Hiking'},
      {'icon': Icons.campaign_rounded, 'title': 'Camping'}, // или кастомная иконка палатки
      {'icon': Icons.directions_walk_rounded, 'title': 'Climbing'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isActive = index == _selectedCategoryIndex;
          final cat = categories[index];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.accentYellow : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Icon(cat['icon'] as IconData, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    cat['title'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  // --- Шторка Уведомлений ---
  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
        context: context,
        useRootNavigator: true, // Чтобы шторка перекрывала нижнюю навигацию
        backgroundColor: AppTheme.cardDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                // Полоска для красоты
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Красивая заглушка "Нет уведомлений"
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.textGrey),
                      SizedBox(height: 16),
                      Text("You're all caught up!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(
                          "Check back later for new trails, weather alerts, and updates from your hiking buddies.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textGrey, height: 1.5)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
    );
  }
}

// Обновленный класс RouteCard
class RouteCard extends StatelessWidget {
  final HikingRoute route;

  const RouteCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: AppTheme.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          // В будущем: переход на экран с деталями маршрута
          context.push('/routes/${route.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ЗАГЛУШКА ДЛЯ КАРТЫ (Map Placeholder)
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                // Легкая линия, отделяющая карту от текста
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Иконка карты по центру
                  const Icon(Icons.map_outlined, size: 64, color: AppTheme.textGrey),
                  // Текст-подсказка
                  Positioned(
                    bottom: 16,
                    child: Text(
                      'Interactive Map Area',
                      style: TextStyle(color: AppTheme.textGrey.withOpacity(0.5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // 2. ИНФОРМАЦИЯ О МАРШРУТЕ
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название и бейдж сложности в одну линию
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          route.name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildDifficultyBadge(route.difficulty),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Локация
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.accentYellow),
                      const SizedBox(width: 6),
                      Text(route.location, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Расстояние
                  Row(
                    children: [
                      const Icon(Icons.route_outlined, size: 16, color: AppTheme.accentYellow),
                      const SizedBox(width: 6),
                      Text('${route.lengthKm} km total distance', style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Виджет для генерации красивого бейджика сложности
  Widget _buildDifficultyBadge(String difficulty) {
    Color badgeColor;
    // Определяем цвет в зависимости от сложности
    switch (difficulty.toLowerCase()) {
      case 'easy':
        badgeColor = Colors.greenAccent;
        break;
      case 'hard':
        badgeColor = Colors.redAccent;
        break;
      default:
        badgeColor = AppTheme.accentYellow; // Medium
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15), // Полупрозрачный фон
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
// lib/features/routes/presentation/routes_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. СТАТИЧНАЯ ШАПКА ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'SHYN',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 28),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Уведомлений пока нет')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. СКРОЛЛИРУЕМАЯ ЧАСТЬ ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Заголовки
                    const Text(
                        'MORNING, EXPLORER',
                        style: TextStyle(color: AppTheme.cardSlate, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2)
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Discover the\ngreat outdoors.',
                      style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 32),

                    // Строка поиска и фильтр
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: Colors.black54, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                      'Search parks, peaks...',
                                      style: TextStyle(color: Colors.black54.withOpacity(0.5), fontSize: 16)
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.tune_rounded, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- КАРТОЧКИ ПИКОВ АЛМАТЫ ---
                    GestureDetector(
                      onTap: () => context.go('/routes/kok_tobe'), // Передаем ID
                      child: const RouteCardMock(badge: 'EASY', location: 'ALMATY, KAZAKHSTAN', title: 'Kok Tobe', isLoaded: true),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/routes/shymbulak'),
                      child: const RouteCardMock(badge: 'MIDDLE', location: 'ALMATY, KAZAKHSTAN', title: 'Shymbulak', isLoaded: true),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/routes/bap'),
                      child: const RouteCardMock(badge: 'HARD', location: 'ALMATY, KAZAKHSTAN', title: 'Big Almaty Peak', isLoaded: false),
                    ),

                    // Отступ внизу
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Класс карточки
class RouteCardMock extends StatelessWidget {
  final String badge;
  final String location;
  final String title;
  final bool isLoaded;

  const RouteCardMock({
    super.key,
    required this.badge,
    required this.location,
    required this.title,
    required this.isLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E), // Цвет фона как в детальном экране
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // --- ЗАГЛУШКА: Иконка горы на фоне ---
          const Center(
            child: Icon(
              Icons.terrain_rounded,
              size: 80,
              color: Colors.white24, // Полупрозрачная белая иконка
            ),
          ),

          // Стеклянная панель внизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24), top: Radius.circular(16)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                location,
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLoaded)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            ),
                          const SizedBox(width: 8),
                          _buildPdfDifficultyBadge(badge),
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

  Widget _buildPdfDifficultyBadge(String difficulty) {
    Color badgeColor;
    switch (difficulty.toUpperCase()) {
      case 'HARD':
        badgeColor = const Color(0xFFFF5252);
        break;
      case 'EASY':
        badgeColor = const Color(0xFF4CAF50);
        break;
      default:
        badgeColor = const Color(0xFFFFC107);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: badgeColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rate_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            difficulty,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
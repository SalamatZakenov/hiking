// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const DashboardScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // ПРОФЕССИОНАЛЬНЫЙ ТРЮК:
    // Проверяем, открыта ли сейчас вкладка Карты (у нее индекс 1 в твоем app_router)
    final isMapScreen = navigationShell.currentIndex == 1;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Основной контент (экраны)
          navigationShell,

          // Показываем нижнее меню ТОЛЬКО если мы НЕ на экране карты
          if (!isMapScreen)
            Positioned(
              left: 24,
              right: 24,
              bottom: 34,
              child: Container(
                height: 72, // Фиксированная высота
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_filled),
                    _buildNavItem(1, Icons.explore_rounded), // Иконка карты
                    _buildNavItem(2, Icons.favorite_rounded),
                    _buildNavItem(3, Icons.person_rounded),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Виджет одной кнопки навигации
  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = navigationShell.currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // ВОТ СЮДА МЫ ВСТАВИЛИ ПРАВИЛЬНЫЙ КОД ПЕРЕХОДА
        navigationShell.goBranch(
          index,
          // initialLocation: true заставляет вкладку сбрасываться к начальному состоянию, если на нее нажали повторно
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      child: SizedBox(
        width: 60,
        height: 72, // На всю высоту контейнера для легкого нажатия
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: isSelected ? AppTheme.accentYellow : AppTheme.textGrey.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
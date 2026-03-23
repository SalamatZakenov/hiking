// lib/features/dashboard/dashboard_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const DashboardScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // Временно скрываем меню на карте (если карта это индекс 2)
    final isMapScreen = navigationShell.currentIndex == 2;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      // Просто обычный Stack, он сам наложит панель поверх списков
      body: Stack(
        children: [
          navigationShell,

          if (!isMapScreen)
            Positioned(
              left: 24,
              right: 24,
              bottom: 34,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.iconDark.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.home_filled),
                        _buildNavItem(1, Icons.people_alt_rounded),
                        _buildNavItem(2, Icons.map_rounded),
                        _buildNavItem(3, Icons.favorite_rounded),
                        _buildNavItem(4, Icons.person_rounded),
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

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = navigationShell.currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      child: SizedBox(
        width: 50,
        height: 72,
        child: Center(
          child: Icon(
            icon,
            size: 26,
            color: isSelected ? Colors.white : AppTheme.cardSlate.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
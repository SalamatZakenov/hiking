// lib/features/dashboard/dashboard_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardScreen({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    if (index == 2) {
      context.push('/map');
    } else {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // <--- Контент скроллится ПОД панелью
      backgroundColor: Colors.transparent,
      body: navigationShell,

      // Вместо SafeArea используем Padding, чтобы панель "висела" над контентом
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          // Добавляем отступ снизу под системную полоску iPhone + еще 8 пикселей
          bottom: MediaQuery.of(context).padding.bottom + 8,
          top: 8,
        ),
        child: ClipRRect( // <--- Обрезаем эффект стекла по краям
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter( // <--- ЭФФЕКТ МАТОВОГО СТЕКЛА
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35), // <--- Панель теперь полупрозрачная!
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)), // Легкая светлая рамка
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, Icons.home_filled, 0),
                  _buildNavItem(context, Icons.people_alt_outlined, 1),

                  // --- ЦЕНТРАЛЬНАЯ КНОПКА КАРТЫ ---
                  GestureDetector(
                    onTap: () => _onTap(context, 2),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                          ]
                      ),
                      child: const Icon(Icons.map_rounded, color: Colors.black, size: 28),
                    ),
                  ),

                  _buildNavItem(context, Icons.favorite_border_rounded, 3),
                  _buildNavItem(context, Icons.person_outline_rounded, 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index) {
    final isSelected = navigationShell.currentIndex == index;
    return GestureDetector(
      onTap: () => _onTap(context, index),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.transparent,
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 26,
        ),
      ),
    );
  }
}
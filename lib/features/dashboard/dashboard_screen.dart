// lib/features/dashboard/dashboard_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../map/presentation/map_screen.dart';

class DashboardScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardScreen({super.key, required this.navigationShell});

  // Элементы навигации: иконка + название
  static const List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.search_rounded, 'label': 'Explore'},
    {'icon': Icons.people_alt_rounded, 'label': 'Feed'},
    {'icon': Icons.bar_chart, 'label': 'Activity'},
    {'icon': Icons.person_rounded, 'label': 'Profile'},
  ];

  int _getRealIndex(int uiIndex) {
    if (uiIndex >= 2) return uiIndex + 1;
    return uiIndex;
  }

  int _getUiIndex(int realIndex) {
    if (realIndex >= 3) return realIndex - 1;
    if (realIndex == 2) return 0;
    return realIndex;
  }

  void _onTap(BuildContext context, int index) {
    final realIndex = _getRealIndex(index);
    navigationShell.goBranch(
      realIndex,
      initialLocation: realIndex == navigationShell.currentIndex,
    );
  }

  Route _createMapRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const MapScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            alignment: const Alignment(0.8, 0.9),
            scale: CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      opaque: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: navigationShell,
      bottomNavigationBar: _buildLiquidGlassBar(context),
    );
  }

  Widget _buildLiquidGlassBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 4),
        child: Row(
          children: [
            // Стеклянная панель: стала прозрачнее и более размытой
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Усилили размытие
                  child: Container(
                    height: 74,
                    decoration: BoxDecoration(
                      color: Color(0xFF00E6FF).withOpacity(0.05), // Сделали более прозрачным (стеклянным)
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Color(0xFF00E6FF).withOpacity(0.1)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildAnimatedIndicator(),
                        Row(
                          children: List.generate(_navItems.length, (index) {
                            final isSelected = _getUiIndex(navigationShell.currentIndex) == index;
                            return Expanded(
                              child: _buildNavItem(
                                  context,
                                  _navItems[index]['icon'] as IconData,
                                  _navItems[index]['label'] as String,
                                  index,
                                  isSelected
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildMapActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIndicator() {
    final int uiIndex = _getUiIndex(navigationShell.currentIndex);
    final int count = _navItems.length;
    final double alignmentX = -1.0 + (uiIndex * (2.0 / (count - 1)));

    return AnimatedAlign(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      alignment: Alignment(alignmentX, 0),
      child: FractionallySizedBox(
        widthFactor: 1.0 / count,
        child: Center(
          child: Container(
            width: 77,
            height: 64,
            decoration: BoxDecoration(
              // Мутный бесцветный индикатор (полупрозрачный белый)
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, bool isSelected) {
    // Тёмно-синий цвет для выбранного состояния
    final color = Colors.white;

    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.1 : 1.0,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(_createMapRoute());
      },
      child: Container(
        height: 74,
        width: 74,
        decoration: BoxDecoration(
          color: const Color(0xFF092547), // Кнопка карты осталась зеленой для акцента
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: const Color(0xFF212C39).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: const Icon(Icons.near_me_outlined, color: Colors.white, size: 32),
      ),
    );
  }
}
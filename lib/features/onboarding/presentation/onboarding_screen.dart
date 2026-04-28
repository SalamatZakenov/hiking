// lib/features/onboarding/presentation/onboarding_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Основа под картинку
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. ФОНОВАЯ КАРТИНКА ГОР
          Image.asset(
            'assets/onboarding.png',
            fit: BoxFit.cover,
          ),

          // Темный градиент поверх картинки, чтобы карточка читалась
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1), // Сверху почти прозрачно, так как текста больше нет
                  Colors.transparent,
                  Colors.black.withOpacity(0.6), // Снизу затемняем для карточки
                  Colors.black.withOpacity(0.9), // Самый низ почти черный
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // 2. ОСНОВНОЙ КОНТЕНТ (Только карточка и кнопка внизу)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(), // Сдвигает всё содержимое в самый низ экрана

                  // --- СТЕКЛЯННАЯ КАРТОЧКА МАРШРУТА ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.4), // Полупрозрачный темный фон
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min, // Занимает только нужное место
                          children: [
                            _buildTimelineItem(Icons.location_on_rounded, 'START POINT', 'Your Base Camp • 1,200m', isFirst: true),
                            _buildTimelineItem(Icons.directions_walk_rounded, 'LIVE TRACKING', 'Current Pace • 3.2 km/h'),
                            _buildTimelineItem(Icons.flag_rounded, 'SUMMIT GOAL', "Eagle's Peak • 3,450m", isLast: true),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- НИЖНЯЯ КНОПКА ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.push('/auth-selection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B).withOpacity(0.8), // Темная кнопка
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(color: Colors.white.withOpacity(0.1)), // Тонкая рамка
                        ),
                      ),
                      child: const Text(
                        'Lets Try and Get Started',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ЭЛЕМЕНТ ТАЙМЛАЙНА (Точки маршрута) ---
  Widget _buildTimelineItem(IconData icon, String title, String subtitle, {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левая часть: Кружок и линия
          Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Очень темный фон иконки
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: Colors.white.withOpacity(0.15), // Тонкая светлая линия
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Правая часть: Тексты
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 4), // Отступ снизу для линии
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      title,
                      style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 4),
                  Text(
                      subtitle,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
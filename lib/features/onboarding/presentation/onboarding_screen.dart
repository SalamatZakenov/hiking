// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark, // Гарантируем темный фон везде
      body: Stack(
        children: [
          // 1. Плавный градиент на весь экран
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE5E5E5), // Светлый верх как в макете
                    AppTheme.bgDark,   // Плавный переход в темный
                    AppTheme.bgDark,
                  ],
                  stops: [0.0, 0.4, 1.0], // Градиент заканчивается на 40% экрана
                ),
              ),
            ),
          ),

          // 2. Основной контент
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // Карточка с логотипом
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Сама темная карточка
                        Container(
                          margin: const EdgeInsets.only(top: 50),
                          padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Заголовок
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  children: [
                                    TextSpan(text: 'Track Every '),
                                    TextSpan(text: 'Step', style: TextStyle(color: AppTheme.accentYellow)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Подзаголовок
                              const Text(
                                'Stay on course with real-time GPS\ntracking and offline maps.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.5),
                              ),
                              const SizedBox(height: 40),

                              // Таймлайн
                              _buildTimelineItem(Icons.location_on, 'START POINT', 'Your Base Camp • 1,200m', isFirst: true),
                              _buildTimelineItem(Icons.directions_walk, 'LIVE TRACKING', 'Current Pace • 3.2 km/h', isHighlight: true),
                              _buildTimelineItem(Icons.flag, 'SUMMIT GOAL', "Eagle's Peak • 3,450m", isLast: true),

                              const Spacer(),

                              // Индикаторы страниц (Dots)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildDot(false),
                                  const SizedBox(width: 6),
                                  _buildDot(true), // Активный
                                  const SizedBox(width: 6),
                                  _buildDot(false),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Логотип (Круг поверх карточки)
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.accentYellow, width: 4),
                            ),
                            // Иконка гор (ближе к макету)
                            child: const Center(
                              child: Icon(Icons.terrain_rounded, size: 50, color: AppTheme.accentYellow),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Нижняя кнопка (Принудительно красим в нужный цвет)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentYellow, // Горчичный цвет
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () {
                      context.push('/auth-selection');
                    },
                    child: const Text('Lets Try and Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      height: 6,
      width: isActive ? 32 : 6,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentYellow : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildTimelineItem(IconData icon, String title, String subtitle, {bool isFirst = false, bool isLast = false, bool isHighlight = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левая часть: Иконка и линии
          Column(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isHighlight ? AppTheme.accentYellow : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: isHighlight ? Colors.white : AppTheme.accentYellow),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isHighlight ? AppTheme.accentYellow : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Правая часть: Текст
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28.0, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, color: isHighlight ? AppTheme.accentYellow : Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
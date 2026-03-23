// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // 1. Плавный градиент на фоне (как на макете)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFDCE2E8), // Светло-серый/белый верх
                    Color(0xFF8394A3), // Переходный стальной
                    AppTheme.bgDark,   // Темный низ
                    AppTheme.bgDark,
                  ],
                  stops: [0.0, 0.35, 0.6, 1.0],
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
                  const SizedBox(height: 60), // Отступ сверху

                  // Карточка с контентом и логотипом
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Сама стальная карточка
                        Container(
                          margin: const EdgeInsets.only(top: 50, bottom: 20),
                          padding: const EdgeInsets.fromLTRB(24, 70, 24, 32),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSlate,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Заголовок Track Every Step
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'San Francisco'),
                                  children: [
                                    TextSpan(text: 'Track Every '),
                                    TextSpan(
                                      text: 'Step',
                                      style: TextStyle(
                                        decorationColor: AppTheme.iconDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Подзаголовок
                              const Text(
                                'Stay on course with real-time GPS\ntracking and offline maps.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textLightGrey, fontSize: 15, height: 1.5),
                              ),

                              const SizedBox(height: 40),

                              // Таймлайн (Темные иконки на светлом фоне)
                              _buildTimelineItem(Icons.location_on_rounded, 'START POINT', 'Your Base Camp • 1,200m', isFirst: true),
                              _buildTimelineItem(Icons.directions_walk_rounded, 'LIVE TRACKING', 'Current Pace • 3.2 km/h', isHighlight: true),
                              _buildTimelineItem(Icons.flag_rounded, 'SUMMIT GOAL', "Eagle's Peak • 3,450m", isLast: true),

                              const Spacer(),
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
                              color: AppTheme.iconDark, // Темный фон круга
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.cardSlate.withOpacity(0.5), width: 6), // Внешняя полупрозрачная рамка
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.cardSlate, width: 2), // Внутренняя тонкая рамка
                                shape: BoxShape.circle,
                              ),
                              // Если у тебя есть вырезанный логотип, используй Image.asset,
                              // пока ставлю иконку гор для визуального соответствия
                              child: const Icon(Icons.terrain_rounded, size: 40, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Нижняя кнопка (использует стиль из новой темы)
                  FilledButton(
                    onPressed: () => context.push('/auth-selection'),
                    child: const Text('Lets Try and Get Started'),
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

  // Обновленный таймлайн под новый дизайн
  Widget _buildTimelineItem(IconData icon, String title, String subtitle, {bool isFirst = false, bool isLast = false, bool isHighlight = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левая часть: Темный кружок и тонкая линия
          Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.iconDark, // Темно-синий кружок
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: isHighlight ? Colors.white : AppTheme.cardSlate),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppTheme.iconDark.withOpacity(0.3), // Темная полупрозрачная линия
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Правая часть: Текст
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textLightGrey, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
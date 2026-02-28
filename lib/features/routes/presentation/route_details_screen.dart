// lib/features/routes/presentation/route_details_screen.dart
import 'package:flutter/material.dart';
import '../../../shared/models/route_model.dart';

class RouteDetailsScreen extends StatelessWidget {
  final HikingRoute route; // В реальном приложении лучше передавать ID и грузить данные через Provider/BLoC

  const RouteDetailsScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(route.name),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {})
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Галерея (пока Placeholder)
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[850],
              child: const Center(
                child: Icon(Icons.terrain, size: 100, color: Colors.white24),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Метаданные
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${route.lengthKm} km • ${route.difficulty}',
                          style: Theme.of(context).textTheme.titleMedium),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(' ${route.rating}', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Предупреждения (Delighter UI)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Опасный участок на 3-м километре. Возможен камнепад после дождей.',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Описание
                  Text('Описание', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Живописный маршрут, проходящий через сосновый лес и выводящий к горному озеру. Подходит для хайкеров со средним уровнем подготовки. Обязательно возьмите треккинговые палки.',
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Кнопка "Начать маршрут" приклеена к низу
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              // В будущем: передаем координаты маршрута в MapScreen и переключаем таб
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Начать маршрут', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
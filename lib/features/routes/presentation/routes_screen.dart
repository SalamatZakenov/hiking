// lib/features/routes/presentation/routes_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/locator.dart';
import '../domain/repositories/route_repository_interface.dart';
import '../../../shared/models/route_model.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  // Достаем репозиторий через локатор
  final IRouteRepository _repository = locator<IRouteRepository>();
  late Future<List<HikingRoute>> _routesFuture;

  @override
  void initState() {
    super.initState();
    _routesFuture = _repository.getRoutes(); // Запрашиваем данные при инициализации
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routes Catalog')),
      body: FutureBuilder<List<HikingRoute>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          // Обработка состояний загрузки
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Маршруты не найдены'));
          }

          final routes = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return RouteCard(route: route); // Вынесли карточку в отдельный виджет
            },
          );
        },
      ),
    );
  }
}

// lib/shared/widgets/route_card.dart
class RouteCard extends StatelessWidget {
  final HikingRoute route;

  const RouteCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Навигация на детальный экран.
          // Роутер нужно будет настроить на прием ID: context.push('/routes/${route.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Icon(Icons.landscape, size: 50, color: Colors.white24),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('${route.lengthKm} km • ${route.difficulty}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
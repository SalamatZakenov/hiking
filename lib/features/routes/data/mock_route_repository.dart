// lib/features/routes/data/mock_route_repository.dart
import '../domain/repositories/route_repository_interface.dart';
import '../../../shared/models/route_model.dart';

class MockRouteRepository implements IRouteRepository {
  // Наша фейковая база данных (чтобы отдавать одни и те же данные во всех методах)
  final List<HikingRoute> _mockRoutes = [
    HikingRoute(
      id: '1',
      name: 'Furmanov Peak',
      location: 'Zailiysky Alatau',
      difficulty: 'Medium',
      lengthKm: 14.5,
      category: 'peak',
    ),
    HikingRoute(
      id: '2',
      name: 'Ile-Alatau Park',
      location: 'Almaty Region',
      difficulty: 'Easy',
      lengthKm: 5.0,
      category: 'park',
    ),
    HikingRoute(
      id: '3',
      name: 'Komsomol Peak',
      location: 'Zailiysky Alatau',
      difficulty: 'Hard',
      lengthKm: 18.2,
      category: 'peak',
    ),
  ];

  @override
  Future<List<HikingRoute>> getRoutes() async {
    // Имитация задержки загрузки из интернета
    await Future.delayed(const Duration(seconds: 1));
    return _mockRoutes;
  }

  // --- НОВЫЕ МЕТОДЫ, КОТОРЫХ НЕ ХВАТАЛО ---

  @override
  Future<HikingRoute?> getRouteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Ищем маршрут по ID. Если не найдем, возвращаем null
    try {
      return _mockRoutes.firstWhere((route) => route.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<HikingRoute>> getSavedOfflineRoutes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Для мока (теста) просто вернем первый маршрут, как будто он сохранен в кеше
    return [_mockRoutes.first];
  }
}
// lib/features/routes/data/mock_route_repository.dart
import '../domain/repositories/route_repository_interface.dart';
import '../../../../shared/models/route_model.dart';

class MockRouteRepository implements IRouteRepository {
  final List<HikingRoute> _mockRoutes = [
    HikingRoute(id: '1', name: 'Eagle Pass', imageUrl: 'placeholder1', lengthKm: 12.5, difficulty: 'Hard', rating: 4.8),
    HikingRoute(id: '2', name: 'Pine Valley', imageUrl: 'placeholder2', lengthKm: 5.0, difficulty: 'Easy', rating: 4.5),
    HikingRoute(id: '3', name: 'Medeu - Shymbulak', imageUrl: 'placeholder3', lengthKm: 8.2, difficulty: 'Medium', rating: 4.9),
  ];

  @override
  Future<List<HikingRoute>> getRoutes() async {
    // Имитируем задержку сети или чтения из БД
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockRoutes;
  }

  @override
  Future<HikingRoute?> getRouteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockRoutes.firstWhere((route) => route.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<HikingRoute>> getSavedOfflineRoutes() async {
    // Имитация локально сохраненных маршрутов
    return [_mockRoutes.first];
  }
}
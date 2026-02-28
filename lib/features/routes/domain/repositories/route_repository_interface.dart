// lib/features/routes/domain/repositories/route_repository_interface.dart
import '../../../../shared/models/route_model.dart';

abstract class IRouteRepository {
  Future<List<HikingRoute>> getRoutes();
  Future<HikingRoute?> getRouteById(String id);
  Future<List<HikingRoute>> getSavedOfflineRoutes();
}
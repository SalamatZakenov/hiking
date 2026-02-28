// lib/core/services/location/location_service_interface.dart
import 'dart:async';

class GeoPosition {
  final double latitude;
  final double longitude;
  final double accuracy;

  GeoPosition({required this.latitude, required this.longitude, required this.accuracy});
}

abstract class ILocationService {
  /// Проверка разрешений (Permissions)
  Future<bool> checkAndRequestPermissions();

  /// Получить текущую точку разово
  Future<GeoPosition?> getCurrentPosition();

  /// Подписаться на постоянное обновление (Трекинг)
  Stream<GeoPosition> getPositionStream();
}
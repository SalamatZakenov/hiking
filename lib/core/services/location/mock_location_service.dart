// lib/core/services/location/mock_location_service.dart
import 'dart:async';
import 'location_service_interface.dart';

class MockLocationService implements ILocationService {
  @override
  Future<bool> checkAndRequestPermissions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Всегда даем разрешение в моке
  }

  @override
  Future<GeoPosition?> getCurrentPosition() async {
    return GeoPosition(latitude: 43.2220, longitude: 76.8512, accuracy: 5.0); // Координаты Алматы (Медеу)
  }

  @override
  Stream<GeoPosition> getPositionStream() async* {
    // Имитируем движение пользователя по прямой, выдавая новую точку каждую секунду
    double lat = 43.2220;
    double lng = 76.8512;

    while (true) {
      await Future.delayed(const Duration(seconds: 1));
      lat += 0.0001; // Сдвиг на север
      lng += 0.0001; // Сдвиг на восток
      yield GeoPosition(latitude: lat, longitude: lng, accuracy: 4.0);
    }
  }
}
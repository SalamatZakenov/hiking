// lib/features/routes/providers/route_provider.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/route_model.dart';
import '../data/services/route_service.dart';
import '../utils/gpx_parser.dart'; // Наш парсер

class RouteProvider with ChangeNotifier {
  final RouteService _service = RouteService();

  List<RouteModel> _routes = [];
  bool _isLoading = false;
  String? _error;

  List<RouteModel> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;

// lib/features/routes/providers/route_provider.dart

  Future<void> loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routes = await _service.fetchRoutes();

      // ПРОХОДИМСЯ ПО ВСЕМ МАРШРУТАМ ИЗ БАЗЫ
      for (int i = 0; i < _routes.length; i++) {

        // ПРОВЕРЯЕМ, ПРИСЛАЛ ЛИ БЭКЕНД ССЫЛКУ НА GPX
        final gpxUrl = _routes[i].gpxUrl;

        if (gpxUrl != null && gpxUrl.isNotEmpty) {
          // Скачиваем трек из интернета!
          final gpxData = await GpxParser.loadRouteFromNetwork(gpxUrl);

          if (gpxData != null && gpxData.trackPoints.isNotEmpty) {
            _routes[i] = _routes[i].copyWith(
              latitude: gpxData.trackPoints.last.latitude,       // Центр - это финиш
              longitude: gpxData.trackPoints.last.longitude,
              trailhead: gpxData.trackPoints.first,              // Старт
              trackPoints: gpxData.trackPoints,                  // Линия
              waypoints: gpxData.waypoints,                      // Метки
            );
          }
        }
      }

      debugPrint('✅ Успешно спарсили и склеили маршрутов: ${_routes.length}');
      await _calculateDistances();
    } catch (e) {
      debugPrint('❌ ОШИБКА В PROVIDER: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // ... (метод _calculateDistances оставляем без изменений)
  Future<void> _calculateDistances() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userLatLng = LatLng(position.latitude, position.longitude);
      final distanceCalc = const Distance();

      for (var route in _routes) {
        final routeLatLng = LatLng(route.latitude, route.longitude);
        final meters = distanceCalc.distance(userLatLng, routeLatLng);
        route.calculatedDistance = meters / 1000;
      }
    } catch (e) {
      debugPrint('❌ Ошибка при расчете дистанции: $e');
    }
  }
}
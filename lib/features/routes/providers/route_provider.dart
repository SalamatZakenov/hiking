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

  Future<void> loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routes = await _service.fetchRoutes();

      // ПРОХОДИМСЯ ПО КАЖДОМУ И ИЩЕМ ЛОКАЛЬНЫЙ GPX ФАЙЛ
      for (int i = 0; i < _routes.length; i++) {
        String? localGpxPath;

        // ИЩЕМ ПО АНГЛИЙСКОМУ ИМЕНИ ИЗ БАЗЫ!
        final routeNameLower = _routes[i].name.toLowerCase();

        if (routeNameLower.contains('furmanova') || routeNameLower.contains('фурманов')) {
          localGpxPath = 'assets/routes/furmanov.gpx';
        } else if (routeNameLower.contains('panorama') || routeNameLower.contains('панорама')) {
          localGpxPath = 'assets/routes/panorama.gpx';
        }

        // Если нашли файл - Вклеиваем его координаты
        if (localGpxPath != null) {
          final gpxData = await GpxParser.loadRoute(localGpxPath);

          if (gpxData != null && gpxData.trackPoints.isNotEmpty) {
            _routes[i] = _routes[i].copyWith(
              latitude: gpxData.trackPoints.last.latitude,
              longitude: gpxData.trackPoints.last.longitude,
              trailhead: gpxData.trackPoints.first,
              trackPoints: gpxData.trackPoints,
              waypoints: gpxData.waypoints,
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
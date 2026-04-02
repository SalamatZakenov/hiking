// lib/features/routes/providers/route_provider.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/route_model.dart';
import '../data/services/route_service.dart';

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
      debugPrint('✅ Успешно спарсили маршрутов: ${_routes.length}');
      await _calculateDistances();
    } catch (e) {
      debugPrint('❌ ОШИБКА В PROVIDER: $e');
      // Теперь скрытых ошибок не будет, мы выведем её на экран!
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
      debugPrint('⚠️ Ошибка геолокации: $e');
    }
  }
}
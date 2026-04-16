import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/route_model.dart';

class RouteProvider extends ChangeNotifier {
  List<RouteModel> _routes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  List<RouteModel> get routes => _routes;

  List<String> get categories {
    final cats = _routes.map((r) => r.category.toUpperCase()).toSet().toList();
    cats.insert(0, 'ALL');
    return cats;
  }

  List<RouteModel> get filteredRoutes {
    return _routes.where((route) {
      final matchesCategory = _selectedCategory == 'ALL' || route.category.toUpperCase() == _selectedCategory;
      final matchesSearch = route.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          route.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // --- ГЛАВНЫЙ МЕТОД ДЛЯ ЗАГРУЗКИ ТОЧЕК ---
  Future<void> loadGpxForRoute(String routeId) async {
    final index = _routes.indexWhere((r) => r.id == routeId);
    if (index == -1) return;

    final route = _routes[index];

    // Если точки уже загружены — не качаем заново
    if (route.cachedGpxPoints != null && route.cachedGpxPoints!.isNotEmpty) return;
    if (route.gpxUrl == null || route.gpxUrl!.isEmpty) return;

    try {
      final response = await Dio().get(route.gpxUrl!);
      final xmlString = response.data.toString();

      // Парсим координаты из XML
      final RegExp regExp = RegExp(r'<trkpt lat="([-+]?[\d.]+)" lon="([-+]?[\d.]+)"');
      final matches = regExp.allMatches(xmlString);

      List<LatLng> points = [];
      for (var m in matches) {
        double lat = double.parse(m.group(1)!);
        double lon = double.parse(m.group(2)!);
        if (lat != 0 && lon != 0) points.add(LatLng(lat, lon));
      }

      if (points.isNotEmpty) {
        // Обновляем маршрут в списке, добавляя ему скачанные точки
        _routes[index] = route.copyWith(cachedGpxPoints: points);
        notifyListeners(); // Карта увидит изменения и нарисует линию
      }
    } catch (e) {
      print('Ошибка загрузки GPX в провайдере: $e');
    }
  }

  Future<void> fetchRoutes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await Dio().get(
        'https://shyn-api.site/api/routes',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _routes = data.map((json) => RouteModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Ошибка загрузки: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchRoutes(String query) { _searchQuery = query; notifyListeners(); }
  void selectCategory(String category) { _selectedCategory = category; notifyListeners(); }
  RouteModel? findById(String id) {
    try { return _routes.firstWhere((r) => r.id == id); } catch (e) { return null; }
  }
}
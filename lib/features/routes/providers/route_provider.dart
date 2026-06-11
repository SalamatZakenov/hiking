import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive/hive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../data/models/route_model.dart';

class RouteProvider extends ChangeNotifier {
  List<RouteModel> _routes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  bool _isRegionDownloaded = false;
  bool _isDownloadingRegion = false;
  double _downloadProgress = 0.0;

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  List<RouteModel> get routes => _routes;

  bool get isRegionDownloaded => _isRegionDownloaded;
  bool get isDownloadingRegion => _isDownloadingRegion;
  double get downloadProgress => _downloadProgress;

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

  // --- МЕГА-ЗАГЛУШКА ВМЕСТО БЭКЕНДА ---
  Future<void> fetchRoutes() async {
    _isLoading = true;
    notifyListeners();

    // Имитируем задержку сети
    await Future.delayed(const Duration(milliseconds: 800));

    _routes = [
      RouteModel(
        id: '1',
        name: 'Furmanov Peak',
        location: 'Almaty, Kazakhstan',
        description: 'A classic and highly rewarding hike near Almaty. Known for the famous swing and breathtaking views of the city and surrounding peaks.',
        elevation: 3053.0,
        difficulty: 'MEDIUM',
        category: 'HIKING',
        latitude: 43.159804,
        longitude: 77.058330,
        // УКАЗЫВАЕМ НАШ ЛОКАЛЬНЫЙ ФАЙЛ
        gpxUrl: 'assets/gpx/furmanov.gpx',
        isLocalGpx: true,
        calculatedDistance: 14.5,
        rating: 4.9,
        imageUrls: [
          'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?q=80&w=1000&auto=format&fit=crop',
        ],
      ),
      RouteModel(
        id: '2',
        name: 'Kok-Zhailau',
        location: 'Almaty, Kazakhstan',
        description: 'The most popular hiking destination in Almaty. A beautiful plateau surrounded by pine forests. Perfect for beginners and family trips.',
        elevation: 2250.0,
        difficulty: 'EASY',
        category: 'HIKING',
        latitude: 43.1610,
        longitude: 77.0145,
        calculatedDistance: 9.8,
        rating: 4.8,
        imageUrls: [
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1000&auto=format&fit=crop',
        ],
      ),
      RouteModel(
        id: '3',
        name: 'Bukreev Peak',
        location: 'Almaty, Kazakhstan',
        description: 'A challenging but incredibly scenic route in the Maloalmatinsky gorge. Offers panoramic views of the Trans-Ili Alatau mountains.',
        elevation: 3010.0,
        difficulty: 'HARD',
        category: 'HIKING',
        latitude: 43.1432,
        longitude: 77.1084,
        calculatedDistance: 16.2,
        rating: 4.7,
        imageUrls: [
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=1000&auto=format&fit=crop',
        ],
      ),
      RouteModel(
        id: '4',
        name: 'Sovetov Peak',
        location: 'BAO, Kazakhstan',
        description: 'A demanding ascent starting from the Big Almaty Lake. Requires good physical condition and proper acclimatization.',
        elevation: 4317.0,
        difficulty: 'HARD',
        category: 'ALPINISM',
        latitude: 43.0315,
        longitude: 76.9855,
        calculatedDistance: 18.0,
        rating: 4.9,
        imageUrls: [
          'https://images.unsplash.com/photo-1486870591958-9b9d0d1dda99?q=80&w=1000&auto=format&fit=crop',
        ],
      ),
    ];

    // Загружаем GPX для тех, у кого он есть
    for (var route in _routes) {
      if (route.gpxUrl != null) {
        await loadGpxForRoute(route.id);
      }
    }

    _isLoading = false;
    notifyListeners();
  }


  Future<void> loadGpxForRoute(String routeId) async {
    final index = _routes.indexWhere((r) => r.id == routeId);
    if (index == -1) return;

    final route = _routes[index];
    if (route.cachedGpxPoints != null && route.cachedGpxPoints!.isNotEmpty) return;

    if (route.gpxUrl != null && route.gpxUrl!.isNotEmpty) {
      try {
        String xmlString;

        // ЕСЛИ ЭТО ЛОКАЛЬНЫЙ ФАЙЛ ИЗ ASSETS
        if (route.isLocalGpx) {
          xmlString = await rootBundle.loadString(route.gpxUrl!);
        }
        // ЕСЛИ ЭТО ССЫЛКА В ИНТЕРНЕТ
        else {
          final response = await Dio().get(route.gpxUrl!);
          xmlString = response.data.toString();
        }

        _parseGpxAndSave(routeId, xmlString);
      } catch (e) {
        print('Ошибка загрузки GPX: $e');
      }
    }
  }

  void _parseGpxAndSave(String routeId, String xmlString) {
    final index = _routes.indexWhere((r) => r.id == routeId);
    if (index == -1) return;

    final RegExp regExp = RegExp(r'<trkpt lat="([-+]?[\d.]+)" lon="([-+]?[\d.]+)"');
    final matches = regExp.allMatches(xmlString);

    List<LatLng> points = [];
    for (var m in matches) {
      double lat = double.parse(m.group(1)!);
      double lon = double.parse(m.group(2)!);
      if (lat != 0 && lon != 0) points.add(LatLng(lat, lon));
    }

    if (points.isNotEmpty) {
      _routes[index] = _routes[index].copyWith(cachedGpxPoints: points);
      notifyListeners();
    }
  }

  void searchRoutes(String query) { _searchQuery = query; notifyListeners(); }
  void selectCategory(String category) { _selectedCategory = category; notifyListeners(); }
  RouteModel? findById(String id) {
    try { return _routes.firstWhere((r) => r.id == id); } catch (e) { return null; }
  }

  // Пустая заглушка для скачивания региона
  Future<void> downloadAlmatyRegion() async {
    _isDownloadingRegion = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _isDownloadingRegion = false;
    _isRegionDownloaded = true;
    notifyListeners();
  }
}
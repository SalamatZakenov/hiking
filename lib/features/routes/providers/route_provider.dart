import 'dart:math' as math;
import 'package:flutter/material.dart';
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

  Future<void> fetchRoutes() async {
    _isLoading = true;
    notifyListeners();

    final routesBox = Hive.box('routesBox');
    final prefs = await SharedPreferences.getInstance();
    _isRegionDownloaded = prefs.getBool('almaty_region_downloaded') ?? false;

    // --- СОЗДАЕМ DIO С БЫСТРЫМ ТАЙМ-АУТОМ (3 секунды) ---
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 3), // Ждем соединения 3 сек
      receiveTimeout: const Duration(seconds: 3), // Ждем данные 3 сек
    ));

    try {
      final token = prefs.getString('auth_token');
      // Используем наш настроенный dio
      final response = await dio.get(
        'https://shyn-api.site/api/routes',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        routesBox.put('cached_routes', data);
        _routes = data.map((json) => RouteModel.fromJson(json)).toList();

        for (var route in _routes) {
          if (route.latitude == 0.0 && route.gpxUrl != null) loadGpxForRoute(route.id);
        }
      }
    } catch (e) {
      print('Офлайн: берем маршруты из кэша (нет сети)');
      final cachedData = routesBox.get('cached_routes');
      if (cachedData != null) {
        _routes = (cachedData as List).map((json) => RouteModel.fromJson(Map<String, dynamic>.from(json))).toList();
        for (var route in _routes) loadGpxForRoute(route.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- УМНОЕ СКАЧИВАНИЕ С ЗАЩИТОЙ ОТ БЛОКИРОВОК ---
  Future<void> downloadAlmatyRegion() async {
    if (_isDownloadingRegion) return;

    _isDownloadingRegion = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      final gpxBox = Hive.box('gpxBox');
      final cacheManager = DefaultCacheManager(); // Менеджер кэша

      // 1. Качаем все GPX треки и Фотографии (30% прогресса)
      for (int i = 0; i < _routes.length; i++) {
        final r = _routes[i];

        if (r.gpxUrl != null && r.gpxUrl!.isNotEmpty && !gpxBox.containsKey('gpx_${r.id}')) {
          try {
            final resp = await Dio().get(r.gpxUrl!);
            final xml = resp.data.toString();
            gpxBox.put('gpx_${r.id}', xml);
            _parseGpxAndSave(r.id, xml);
          } catch(e) {
            print("Не удалось скачать GPX для ${r.name}");
          }
        }

        for (var imgUrl in r.imageUrls) {
          try {
            final fileInfo = await cacheManager.getFileFromCache(imgUrl);
            if (fileInfo == null) {
              await cacheManager.downloadFile(imgUrl);
            }
          } catch(e) {
            // Игнорируем ошибку одной картинки
          }
        }

        _downloadProgress = (i / _routes.length) * 0.3;
        notifyListeners();
      }

      // 2. Вычисляем тайлы (кусочки карты)
      final bounds = LatLngBounds(const LatLng(43.35, 76.70), const LatLng(42.95, 77.35));
      List<String> urlsToDownload = [];

      for (int z = 10; z <= 14; z++) {
        final minTile = _latLngToTile(bounds.northWest, z);
        final maxTile = _latLngToTile(bounds.southEast, z);

        final minX = math.min(minTile.x, maxTile.x);
        final maxX = math.max(minTile.x, maxTile.x);
        final minY = math.min(minTile.y, maxTile.y);
        final maxY = math.max(minTile.y, maxTile.y);

        for (int x = minX; x <= maxX; x++) {
          for (int y = minY; y <= maxY; y++) {
            final s = ['a', 'b', 'c'][(x + y) % 3];
            urlsToDownload.add('https://$s.tile.opentopomap.org/$z/$x/$y.png');
          }
        }
      }

      // 3. Аккуратное скачивание карты (Оставшиеся 70% прогресса)
      int totalTiles = urlsToDownload.length;
      for (int i = 0; i < totalTiles; i++) {
        try {
          final url = urlsToDownload[i];
          // Проверяем, есть ли уже этот кусок в кэше
          final fileInfo = await cacheManager.getFileFromCache(url);

          if (fileInfo == null) {
            // Если нет — качаем и ЖДЕМ завершения
            await cacheManager.downloadFile(url);

            // ВАЖНО: Делаем микро-паузу, чтобы сервер нас не заблокировал (Rate Limit)
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } catch (e) {
          // Если один кусок карты не скачался — ничего страшного, просто идем дальше
          print("Ошибка тайла $i: $e");
        }

        // Обновляем UI каждые 10 тайлов
        if (i % 10 == 0) {
          _downloadProgress = 0.3 + ((i / totalTiles) * 0.7);
          notifyListeners();
        }
      }

      // Успех!
      _isRegionDownloaded = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('almaty_region_downloaded', true);

    } catch (e) {
      print("Глобальная ошибка скачивания региона: $e");
    } finally {
      _isDownloadingRegion = false;
      _downloadProgress = 1.0;
      notifyListeners();
    }
  }

  math.Point<int> _latLngToTile(LatLng latLng, int zoom) {
    final latRad = latLng.latitude * math.pi / 180.0;
    final n = math.pow(2.0, zoom);
    final x = ((latLng.longitude + 180.0) / 360.0 * n).floor();
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
    return math.Point(x, y);
  }

  Future<void> loadGpxForRoute(String routeId) async {
    final index = _routes.indexWhere((r) => r.id == routeId);
    if (index == -1) return;

    final route = _routes[index];
    if (route.cachedGpxPoints != null && route.cachedGpxPoints!.isNotEmpty) return;

    final gpxBox = Hive.box('gpxBox');

    if (gpxBox.containsKey('gpx_$routeId')) {
      _parseGpxAndSave(routeId, gpxBox.get('gpx_$routeId'));
      return;
    }

    if (route.gpxUrl != null && route.gpxUrl!.isNotEmpty) {
      try {
        final response = await Dio().get(route.gpxUrl!);
        _parseGpxAndSave(routeId, response.data.toString());
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
}
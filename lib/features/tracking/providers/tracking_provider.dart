import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/local_track.dart';
import 'package:dio/dio.dart';

enum TrackingStatus { idle, tracking, paused }

class TrackingProvider extends ChangeNotifier {
  TrackingStatus _status = TrackingStatus.idle;
  List<LatLng> _routePoints = [];
  double _totalDistanceKm = 0.0;
  LatLng? _currentLocation;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  List<LocalTrack> _savedTracks = [];
  List<LocalTrack> get savedTracks => _savedTracks;

  List<LocalTrack> _communityTracks = [];
  List<LocalTrack> get communityTracks => _communityTracks;

  TrackingStatus get status => _status;
  bool get isTracking => _status == TrackingStatus.tracking;
  bool get isPaused => _status == TrackingStatus.paused;
  List<LatLng> get routePoints => _routePoints;
  double get totalDistanceKm => _totalDistanceKm;
  LatLng? get currentLocation => _currentLocation;

  String get formattedTime {
    final duration = _stopwatch.elapsed;
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  TrackingProvider() {
    _startListeningLocation();
    loadSavedTracks();
    fetchCommunityPosts();
  }

  // --- 1. ЗАГРУЗКА МОИХ ТРЕКОВ (PROFILE) ---
  Future<void> loadSavedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await Dio().get(
        'https://shyn-api.site/api/routes/user-tracks/my',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _savedTracks = data.map((json) => LocalTrack.fromMap(json)).toList();
        _savedTracks.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (e) {
      print('Ошибка загрузки моих треков: $e');
    }
  }

  // --- 2. ЗАГРУЗКА ЛЕНТЫ (COMMUNITY) ---
  Future<void> fetchCommunityPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await Dio().get(
        'https://shyn-api.site/api/routes/user-tracks/feed', // Правильный эндпоинт ленты
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _communityTracks = data.map((json) => LocalTrack.fromMap(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Ошибка загрузки ленты: $e');
    }
  }

  Future<void> _startListeningLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
    ).listen((Position position) {
      if (position.accuracy > 15.0) return;
      final newPoint = LatLng(position.latitude, position.longitude);
      _currentLocation = newPoint;

      if (_status == TrackingStatus.tracking) {
        if (_routePoints.isNotEmpty) {
          final distanceMeters = Geolocator.distanceBetween(
            _routePoints.last.latitude, _routePoints.last.longitude,
            newPoint.latitude, newPoint.longitude,
          );
          if (distanceMeters < 5.0) return;
          _totalDistanceKm += (distanceMeters / 1000);
        }
        _routePoints.add(newPoint);
      }
      notifyListeners();
    });
  }

  void startTracking() {
    _status = TrackingStatus.tracking;
    _routePoints.clear();
    _totalDistanceKm = 0.0;
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    notifyListeners();
  }

  void pauseTracking() {
    _status = TrackingStatus.paused;
    _stopwatch.stop();
    notifyListeners();
  }

  void resumeTracking() {
    _status = TrackingStatus.tracking;
    _stopwatch.start();
    notifyListeners();
  }

  Future<void> stopTracking() async {
    _status = TrackingStatus.idle;
    _stopwatch.stop();
    _timer?.cancel();
    notifyListeners();
  }

// --- 3. СОХРАНЕНИЕ И ОТПРАВКА НА СЕРВЕР (ВАРИАНТ А) ---
  Future<void> saveCurrentTrack({required String name, required String type, List<String> imageUrls = const []}) async {
    if (_routePoints.isEmpty) {
      await stopTracking();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final trackId = DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Генерируем GPX локально
    StringBuffer sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<gpx version="1.1" creator="HikingApp">');
    sb.writeln('  <trk><name>$name</name><type>$type</type><trkseg>');
    for (var point in _routePoints) {
      sb.writeln('    <trkpt lat="${point.latitude}" lon="${point.longitude}"><time>${DateTime.now().toUtc().toIso8601String()}</time></trkpt>');
    }
    sb.writeln('  </trkseg></trk></gpx>');

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/track_$trackId.gpx';
    await File(filePath).writeAsString(sb.toString());

    // Запоминаем текущую статистику перед очисткой
    final double finalDistance = _totalDistanceKm;
    final int finalDuration = _stopwatch.elapsed.inSeconds;

    // Очищаем UI трекера
    await stopTracking();
    _routePoints.clear();
    _totalDistanceKm = 0.0;
    _stopwatch.reset();
    notifyListeners();

    if (token == null) return;

    try {
      String uploadedGpxUrl = "";

      // ШАГ 1: Загружаем GPX файл на сервер
      FormData gpxFormData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: "track.gpx"),
      });

      final gpxResponse = await Dio().post(
        'https://shyn-api.site/api/routes/upload/gpx',
        data: gpxFormData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (gpxResponse.statusCode == 200 || gpxResponse.statusCode == 201) {
        // Очищаем от возможных лишних кавычек (""), которые иногда возвращает сервер
        uploadedGpxUrl = gpxResponse.data.toString().replaceAll('"', '');
        print('✅ GPX загружен: $uploadedGpxUrl');
      }

      // ШАГ 2: Создаем финальный пост в базе данных
      // Точь-в-точь как просил бэкендщик в своем примере!
      final requestData = {
        "name": name,
        "activityType": type.toUpperCase(), // HIKING, WALKING, RUNNING
        "distanceKm": double.parse(finalDistance.toStringAsFixed(2)), // Округляем до 2 знаков (например, 5.20)
        "durationSec": finalDuration,
        "gpxUrl": uploadedGpxUrl,
        "imageUrls": imageUrls
      };

      print('📤 Отправляем JSON: $requestData');

      await Dio().post(
        'https://shyn-api.site/api/routes/user-tracks',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json', // <-- ВАЖНО: Явно говорим, что это строгий JSON
          },
        ),
        data: jsonEncode(requestData), // <-- ВАЖНО: Переводим наш словарь в правильную JSON-строку
      );

      print('✅ Трек успешно опубликован!');

      // ШАГ 3: Обновляем ленты, чтобы новый пост сразу появился
      await loadSavedTracks();
      await fetchCommunityPosts();

    } catch (e) {
      if (e is DioException) {
        print('❌ Ошибка API: ${e.response?.data}');
      } else {
        print('❌ Ошибка: $e');
      }
    }
  }

  // --- ЛАЙКИ (Оптимистичное обновление) ---
  Future<void> toggleLike(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    // Ищем трек в списках
    int communityIndex = _communityTracks.indexWhere((t) => t.id == trackId);
    int profileIndex = _savedTracks.indexWhere((t) => t.id == trackId);

    if (communityIndex == -1 && profileIndex == -1) return;

    // Берем любой из найденных треков для определения статуса
    final track = communityIndex != -1 ? _communityTracks[communityIndex] : _savedTracks[profileIndex];
    final bool isLiked = track.likedByMe;
    final int newLikes = isLiked ? track.likeCount - 1 : track.likeCount + 1;

    // Функция для создания обновленной копии трека
    LocalTrack updatedTrack(LocalTrack t) {
      final map = t.toMap();
      map['likedByMe'] = !isLiked;
      map['likeCount'] = newLikes;
      return LocalTrack.fromMap(map);
    }

    // Мгновенно обновляем UI
    if (communityIndex != -1) _communityTracks[communityIndex] = updatedTrack(_communityTracks[communityIndex]);
    if (profileIndex != -1) _savedTracks[profileIndex] = updatedTrack(_savedTracks[profileIndex]);

    notifyListeners();

    // Отправляем на бэкенд
    try {
      final url = 'https://shyn-api.site/api/routes/user-tracks/$trackId/like';
      if (!isLiked) {
        await Dio().post(url, options: Options(headers: {'Authorization': 'Bearer $token'}));
      } else {
        await Dio().delete(url, options: Options(headers: {'Authorization': 'Bearer $token'}));
      }
    } catch (e) {
      print('Ошибка лайка: $e');
    }
  }

  Future<void> discardCurrentTrack() async {
    await stopTracking();
    _routePoints.clear();
    _totalDistanceKm = 0.0;
    _stopwatch.reset();
    notifyListeners();
  }

  // --- КОММЕНТАРИИ ---
  Future<List<dynamic>> getComments(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      final response = await Dio().get(
          'https://shyn-api.site/api/routes/user-tracks/$trackId/comments',
          options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      return response.data;
    } catch (e) {
      print('Ошибка загрузки комментов: $e');
      return [];
    }
  }

  Future<void> addComment(String trackId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    try {
      await Dio().post(
          'https://shyn-api.site/api/routes/user-tracks/$trackId/comments',
          data: {"text": text},
          options: Options(headers: {'Authorization': 'Bearer $token'})
      );

      // Локально увеличиваем счетчик комментов, чтобы UI обновился сразу
      void updateCount(List<LocalTrack> list) {
        final index = list.indexWhere((t) => t.id == trackId);
        if (index != -1) {
          final map = list[index].toMap();
          map['commentCount'] = (map['commentCount'] as int) + 1;
          list[index] = LocalTrack.fromMap(map);
        }
      }
      updateCount(_communityTracks);
      updateCount(_savedTracks);
      notifyListeners();
    } catch (e) {
      print('Ошибка отправки коммента: $e');
    }
  }
}
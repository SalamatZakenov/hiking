// lib/features/tracking/providers/tracking_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TrackingStatus { idle, tracking, paused }

class TrackingProvider extends ChangeNotifier {
  TrackingStatus _status = TrackingStatus.idle;
  List<LatLng> _routePoints = [];
  double _totalDistanceKm = 0.0;

  // НОВОЕ: Всегда храним текущую локацию пользователя!
  LatLng? _currentLocation;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

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

  // При создании провайдера сразу начинаем искать пользователя
  TrackingProvider() {
    _startListeningLocation();
  }

  Future<void> _startListeningLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Быстро получаем первую точку, чтобы не ждать
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (e) {}

    // Настраиваем фоновый поток
    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 3, // Обновлять каждые 3 метра
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3);
    }

    // Слушаем координаты ПОСТОЯННО
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);

      // Обновляем синюю точку на карте
      _currentLocation = newPoint;

      // А если включена запись трека - добавляем в линию
      if (_status == TrackingStatus.tracking) {
        if (_routePoints.isNotEmpty) {
          final distanceMeters = Geolocator.distanceBetween(
            _routePoints.last.latitude, _routePoints.last.longitude,
            newPoint.latitude, newPoint.longitude,
          );
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
    if (_currentLocation != null) _routePoints.add(_currentLocation!);
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

  Future<void> saveAndReset(String name) async {
    if (_routePoints.isEmpty && _totalDistanceKm == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('completed_routes');
    List<dynamic> routesList = savedData != null ? jsonDecode(savedData) : [];

    routesList.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'date': DateTime.now().toIso8601String(),
      'distanceKm': _totalDistanceKm,
      'durationStr': formattedTime,
      'points': _routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    });

    await prefs.setString('completed_routes', jsonEncode(routesList));
    _routePoints.clear();
    _totalDistanceKm = 0.0;
    _stopwatch.reset();
    notifyListeners();
  }
}
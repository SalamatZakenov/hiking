// lib/features/tracking/providers/tracking_provider.dart
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
  }

  Future<void> loadSavedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? tracksJson = prefs.getStringList('my_saved_tracks');

    if (tracksJson != null) {
      _savedTracks = tracksJson.map((jsonStr) => LocalTrack.fromJson(jsonStr)).toList();
      _savedTracks.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
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

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (e) {}

    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3);
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);

      _currentLocation = newPoint;

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

  Future<void> saveCurrentTrack({required String name, required String type}) async {
    if (_routePoints.isEmpty) {
      await stopTracking();
      return;
    }

    final trackId = DateTime.now().millisecondsSinceEpoch.toString();

    StringBuffer sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<gpx version="1.1" creator="HikingApp">');
    sb.writeln('  <trk><name>$name</name><type>$type</type><trkseg>');
    for (var point in _routePoints) {
      sb.writeln('    <trkpt lat="${point.latitude}" lon="${point.longitude}">');
      sb.writeln('      <time>${DateTime.now().toUtc().toIso8601String()}</time>');
      sb.writeln('    </trkpt>');
    }
    sb.writeln('  </trkseg></trk></gpx>');

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/track_$trackId.gpx';
    final file = File(filePath);
    await file.writeAsString(sb.toString());

    final newTrack = LocalTrack(
      id: trackId,
      name: name,
      type: type,
      distanceKm: _totalDistanceKm,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      gpxFilePath: filePath,
      date: DateTime.now(),
    );

    _savedTracks.insert(0, newTrack);
    final prefs = await SharedPreferences.getInstance();
    final tracksStringList = _savedTracks.map((t) => t.toJson()).toList();
    await prefs.setStringList('my_saved_tracks', tracksStringList);

    print('✅ Трек успешно сохранен: $name ($type)');

    await stopTracking();
    _routePoints.clear();
    _totalDistanceKm = 0.0;
    _stopwatch.reset();
    notifyListeners();
  }
}
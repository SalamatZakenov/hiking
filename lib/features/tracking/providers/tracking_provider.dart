// lib/features/tracking/providers/tracking_provider.dart
import 'dart:async';
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

  List<LocalTrack> _communityTracks = [];
  List<LocalTrack> get communityTracks => _communityTracks;

  TrackingStatus get status => _status;
  bool get isTracking => _status == TrackingStatus.tracking;
  bool get isPaused => _status == TrackingStatus.paused;
  List<LatLng> get routePoints => _routePoints;
  double get totalDistanceKm => _totalDistanceKm;
  LatLng? get currentLocation => _currentLocation;

  // Фейковая база данных комментариев для Mock-режима
  final Map<String, List<dynamic>> _mockComments = {
    'mock_1': [
      {'username': 'Alisher', 'text': 'Bro, this is amazing! 🔥'},
      {'username': 'Nursultan', 'text': 'Great pace, keep it up.'}
    ]
  };

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

  // --- 1. ЗАГЛУШКА: ПРОФИЛЬ ---
  Future<void> loadSavedTracks() async {
    // Имитация сети
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_name') ?? 'Salamat Zakenov';

    _savedTracks = [
      LocalTrack(
        id: 'mock_profile_1',
        username: username,
        name: 'Morning Kok-Zhailau',
        activityType: 'HIKING',
        distanceKm: 9.8,
        durationSeconds: 14400,
        gpxFilePath: 'assets/gpx/furmanov.gpx', // Используем твой файл
        date: DateTime.now().subtract(const Duration(days: 2)),
        imageUrls: ['https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=1000&auto=format&fit=crop'],
        likeCount: 15,
        commentCount: 0,
        likedByMe: false,
      ),
    ];
    notifyListeners();
  }

  // --- 2. ЗАГЛУШКА: ЛЕНТА (COMMUNITY) ---
  Future<void> fetchCommunityPosts() async {
    await Future.delayed(const Duration(milliseconds: 800));

    _communityTracks = [
      LocalTrack(
        id: 'mock_1',
        username: 'Timur',
        name: 'Medeo - Furmanov Peak',
        activityType: 'ALPINISM',
        distanceKm: 14.5,
        durationSeconds: 18000,
        gpxFilePath: 'assets/gpx/furmanov.gpx',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        imageUrls: [
          'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?q=80&w=1000&auto=format&fit=crop'
        ],
        likeCount: 42,
        commentCount: 2,
        likedByMe: true,
      ),
      LocalTrack(
        id: 'mock_2',
        username: 'Aruzhan',
        name: 'Fast Run at BAO',
        activityType: 'RUNNING',
        distanceKm: 5.2,
        durationSeconds: 3600,
        gpxFilePath: '',
        date: DateTime.now().subtract(const Duration(days: 1)),
        imageUrls: ['https://images.unsplash.com/photo-1522163182402-834f871fd851?q=80&w=1000&auto=format&fit=crop'],
        likeCount: 18,
        commentCount: 0,
        likedByMe: false,
      ),
    ];
    notifyListeners();
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

  // --- 3. ЗАГЛУШКА: СОХРАНЕНИЕ ТРЕКА ---
  Future<void> saveCurrentTrack({required String name, required String type, List<String> imageUrls = const []}) async {
    if (_routePoints.isEmpty) {
      await stopTracking();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_name') ?? 'Salamat Zakenov';
    final trackId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    // Генерируем GPX и сохраняем локально (чтобы мини-карта работала)
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

    // Создаем новый пост для нашей памяти
    final newTrack = LocalTrack(
      id: trackId,
      username: username,
      name: name,
      activityType: type.toUpperCase(),
      distanceKm: _totalDistanceKm,
      durationSeconds: _stopwatch.elapsed.inSeconds,
      gpxFilePath: filePath,
      date: DateTime.now(),
      imageUrls: imageUrls,
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
    );

    // Добавляем его в начало ленты и профиля
    _savedTracks.insert(0, newTrack);
    _communityTracks.insert(0, newTrack);

    await stopTracking();
    _routePoints.clear();
    _totalDistanceKm = 0.0;
    _stopwatch.reset();
    notifyListeners();
    print('✅ Локальный трек успешно сохранен и добавлен в ленту!');
  }

  // --- ЛАЙКИ (Остаются локальными) ---
  Future<void> toggleLike(String trackId) async {
    int communityIndex = _communityTracks.indexWhere((t) => t.id == trackId);
    int profileIndex = _savedTracks.indexWhere((t) => t.id == trackId);

    if (communityIndex == -1 && profileIndex == -1) return;

    final track = communityIndex != -1 ? _communityTracks[communityIndex] : _savedTracks[profileIndex];
    final bool isLiked = track.likedByMe;
    final int newLikes = isLiked ? track.likeCount - 1 : track.likeCount + 1;

    LocalTrack updatedTrack(LocalTrack t) {
      final map = t.toMap();
      map['likedByMe'] = !isLiked;
      map['likeCount'] = newLikes;
      return LocalTrack.fromMap(map);
    }

    if (communityIndex != -1) _communityTracks[communityIndex] = updatedTrack(_communityTracks[communityIndex]);
    if (profileIndex != -1) _savedTracks[profileIndex] = updatedTrack(_savedTracks[profileIndex]);
    notifyListeners();
  }

  Future<void> discardCurrentTrack() async {
    await stopTracking();
    _routePoints.clear();
    _totalDistanceKm = 0.0;
    _stopwatch.reset();
    notifyListeners();
  }

  // --- ЗАГЛУШКИ: КОММЕНТАРИИ ---
  Future<List<dynamic>> getComments(String trackId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockComments[trackId] ?? [];
  }

  Future<void> addComment(String trackId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_name') ?? 'Salamat Zakenov';

    if (!_mockComments.containsKey(trackId)) {
      _mockComments[trackId] = [];
    }

    _mockComments[trackId]!.add({
      'username': username,
      'text': text,
    });

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
  }
}
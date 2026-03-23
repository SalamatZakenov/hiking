// lib/features/map/presentation/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart'; // Добавили Dio для запроса погоды!

enum TrackingState { idle, active, paused }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Dio _dio = Dio(); // Инициализируем Dio

  final Color _mustardYellow = const Color(0xFFDE9E48);
  final Color _panelColor = const Color(0xFF423B33);
  final Color _routeGreen = const Color(0xFF55C73A);

  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  bool _isPanelExpanded = false;

  // --- НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ АКТИВНОСТИ И ПОГОДЫ ---
  String _selectedActivity = 'Hiking';
  final List<String> _activities = ['Hiking', 'Walking', 'Running', 'Cycling'];

  String _weatherText = 'Loading...';
  IconData _weatherIcon = Icons.cloud_outlined;

  TrackingState _trackingState = TrackingState.idle;
  final List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;

  Timer? _timer;
  int _secondsElapsed = 0;
  double _distanceMeters = 0.0;
  final double _elevationGain = 0.0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Сразу после получения локации запрашиваем погоду!
      _fetchWeather(position.latitude, position.longitude);

    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  // --- МЕТОД ЗАПРОСА ПОГОДЫ В РЕАЛЬНОМ ВРЕМЕНИ ---
  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );

      if (response.statusCode == 200) {
        final current = response.data['current_weather'];
        final int temp = current['temperature'].round();
        final int code = current['weathercode'];

        setState(() {
          _weatherText = '$temp°C, ${_getWeatherDescription(code)}';
          _weatherIcon = _getWeatherIcon(code);
        });
      }
    } catch (e) {
      setState(() {
        _weatherText = 'Weather unavailable';
        _weatherIcon = Icons.cloud_off_rounded;
      });
    }
  }

  // Расшифровка кодов погоды (WMO Code)
  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if (code == 1 || code == 2 || code == 3) return 'Partly cloudy';
    if (code >= 45 && code <= 48) return 'Fog';
    if (code >= 51 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code == 1 || code == 2 || code == 3) return Icons.cloud_queue_rounded;
    if (code >= 45 && code <= 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.water_drop_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.flash_on_rounded;
    return Icons.cloud_rounded;
  }

  // --- ВЫБОР АКТИВНОСТИ (BOTTOM SHEET) ---
  void _showActivitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _panelColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._activities.map((activity) => ListTile(
                leading: Icon(_getActivityIcon(activity), color: _mustardYellow),
                title: Text(activity, style: const TextStyle(color: Colors.white, fontSize: 18)),
                trailing: _selectedActivity == activity ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent) : null,
                onTap: () {
                  setState(() => _selectedActivity = activity);
                  Navigator.pop(context); // Закрываем меню
                },
              )),
            ],
          ),
        );
      },
    );
  }

  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'Hiking': return Icons.hiking_rounded;
      case 'Walking': return Icons.directions_walk_rounded;
      case 'Running': return Icons.directions_run_rounded;
      case 'Cycling': return Icons.directions_bike_rounded;
      default: return Icons.directions_walk_rounded;
    }
  }

  // --- ОСТАЛЬНАЯ ЛОГИКА ТРЕКИНГА ---
  void _startTracking() {
    setState(() {
      _trackingState = TrackingState.active;
      _isPanelExpanded = false;
      _secondsElapsed = 0;
      _distanceMeters = 0.0;
      _routePoints.clear();
      if (_currentLocation != null) _routePoints.add(_currentLocation!);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3),
    ).listen((Position position) {
      if (_trackingState == TrackingState.active) {
        setState(() {
          final newPoint = LatLng(position.latitude, position.longitude);
          if (_routePoints.isNotEmpty) {
            _distanceMeters += const Distance().distance(_routePoints.last, newPoint);
          }
          _routePoints.add(newPoint);
          _currentLocation = newPoint;
          _mapController.move(newPoint, _mapController.camera.zoom);
        });
      }
    });
  }

  void _pauseTracking() {
    setState(() => _trackingState = TrackingState.paused);
    _timer?.cancel();
    _positionStream?.pause();
  }

  void _resumeTracking() {
    setState(() {
      _trackingState = TrackingState.active;
      _isPanelExpanded = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
    _positionStream?.resume();
  }

  void _stopTracking() {
    _pauseTracking();
    setState(() {
      _trackingState = TrackingState.idle;
      _isPanelExpanded = true;
      _routePoints.clear();
      _secondsElapsed = 0;
      _distanceMeters = 0;
    });
    _positionStream?.cancel();
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  String get _formattedTime {
    final h = _secondsElapsed ~/ 3600;
    final m = (_secondsElapsed % 3600) ~/ 60;
    final s = _secondsElapsed % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          _buildMap(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/routes'),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: _mustardYellow,
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(color: _mustardYellow, borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(padding: EdgeInsets.all(12.0), child: Icon(Icons.layers_rounded, color: Colors.white)),
                            Container(height: 1, width: 24, color: Colors.white54),
                            const Padding(padding: EdgeInsets.all(12.0), child: Icon(Icons.view_in_ar_rounded, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(color: _mustardYellow, borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _zoomIn),
                            Container(height: 1, width: 24, color: Colors.white54),
                            IconButton(icon: const Icon(Icons.remove, color: Colors.white), onPressed: _zoomOut),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildRoutePanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoadingLocation) return Center(child: CircularProgressIndicator(color: _mustardYellow));

    final initialCenter = _currentLocation ?? const LatLng(43.2300, 76.8520);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: initialCenter, initialZoom: 16.0),
      children: [
        TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', userAgentPackageName: 'com.yourname.hikingapp'),
        if (_routePoints.isNotEmpty)
          PolylineLayer(polylines: [Polyline(points: _routePoints, strokeWidth: 6.0, color: _routeGreen, borderStrokeWidth: 1.5, borderColor: Colors.black.withOpacity(0.3))]),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 30, height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRoutePanel() {
    final double displayDistanceKm = _distanceMeters / 1000;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5 && !_isPanelExpanded) {
          setState(() => _isPanelExpanded = true);
        } else if (details.delta.dy > 5 && _isPanelExpanded) {
          setState(() => _isPanelExpanded = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _panelColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16, top: 8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),

            // --- ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ (ПОЯВЛЯЕТСЯ ПРИ РАСКРЫТИИ) ---
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 16),
              secondChild: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  children: [
                    // КНОПКА ВЫБОРА АКТИВНОСТИ
                    GestureDetector(
                      onTap: _showActivitySelector,
                      child: _buildExtraInfoRow(_getActivityIcon(_selectedActivity), 'Activity', _selectedActivity),
                    ),
                    const SizedBox(height: 16),

                    // СТРОКА ПОГОДЫ (Обновляется через API)
                    _buildExtraInfoRow(_weatherIcon, 'Weather', _weatherText, showArrow: false),

                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1)),
                  ],
                ),
              ),
              crossFadeState: _isPanelExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(value: _formattedTime, unit: '', label: 'Time'),
                _buildStatItem(value: displayDistanceKm.toStringAsFixed(2), unit: 'km', label: 'Distance'),
                _buildStatItem(value: _elevationGain.toInt().toString(), unit: 'm', label: 'Elev. gain'),
              ],
            ),

            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraInfoRow(IconData icon, String title, String value, {bool showArrow = true}) {
    return Container(
      color: Colors.transparent, // Чтобы клик срабатывал по всей строке
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _mustardYellow, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (showArrow) const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38, size: 20) else const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String value, required String unit, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w400)),
            if (unit.isNotEmpty) Text(' $unit', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_trackingState == TrackingState.idle) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _mustardYellow, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 28),
          label: const Text('Start Tracking', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          onPressed: _startTracking,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _trackingState == TrackingState.active ? Colors.white24 : _mustardYellow, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            icon: Icon(_trackingState == TrackingState.active ? Icons.pause : Icons.play_arrow, color: Colors.white),
            label: Text(_trackingState == TrackingState.active ? 'Pause' : 'Resume', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _trackingState == TrackingState.active ? _pauseTracking : _resumeTracking,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.9), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            icon: const Icon(Icons.stop, color: Colors.white),
            label: const Text('Stop', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: _stopTracking,
          ),
        ),
      ],
    );
  }
}
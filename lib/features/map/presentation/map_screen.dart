// lib/features/map/presentation/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart'; // Не забудь импорт для кнопки Вниз!
import '../../../core/theme/app_theme.dart';

enum TrackingState { idle, active, paused }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // Локация
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  String? _errorMessage;
  bool _isTopoMap = false; // Старый переключатель топографии

  // Данные трекинга
  TrackingState _trackingState = TrackingState.idle;
  final List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;

  // Таймер и дистанция
  Timer? _timer;
  int _secondsElapsed = 0;
  double _distanceMeters = 0.0;
  double _elevationGain = 0.0; // Заглушка

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
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permission denied.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingLocation = false;
      });
    }
  }

  // --- СТАРЫЕ МЕТОДЫ УПРАВЛЕНИЯ КАРТОЙ ---
  void _centerOnUser() {
    if (_currentLocation != null) _mapController.move(_currentLocation!, 16.0);
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  // --- ЛОГИКА ТРЕКЕРА (Остается прежней) ---
  void _startTracking() {
    setState(() {
      _trackingState = TrackingState.active;
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
    setState(() => _trackingState = TrackingState.active);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
    _positionStream?.resume();
  }

  void _stopTracking() {
    _pauseTracking();
    final double distanceKm = _distanceMeters / 1000;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Finish Hike?', style: TextStyle(color: Colors.white)),
        content: Text(
            'Distance: ${distanceKm.toStringAsFixed(2)} km\nTime: $_formattedTime\n\nSave to history?',
            style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _resumeTracking(); }, child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF88FF66)), // Зеленый из Figma
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _trackingState = TrackingState.idle;
                _routePoints.clear();
                _secondsElapsed = 0;
                _distanceMeters = 0;
              });
              _positionStream?.cancel();
            },
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          _buildMapBody(),

          // --- СТАРЫЕ КНОПКИ СПРАВА (В столбик) ---
          Positioned(
            right: 16,
            top: 100, // Чуть ниже, чтобы не мешать челке
            child: Column(
              children: [
                // Кнопка Вниз (Свернуть) - ДОБАВИЛИ ДЛЯ ПОЛНОТЫ ДИЗАЙНА
                _buildMapButton(Icons.keyboard_arrow_down_rounded, () => context.go('/routes')),
                const SizedBox(height: 16),

                // Старые кнопки управления картой
                _buildMapButton(_isTopoMap ? Icons.terrain_rounded : Icons.layers_rounded, () => setState(() => _isTopoMap = !_isTopoMap), isActive: _isTopoMap),
                const SizedBox(height: 16),
                _buildMapButton(Icons.add, _zoomIn),
                const SizedBox(height: 8),
                _buildMapButton(Icons.remove, _zoomOut),
                const SizedBox(height: 16),
                _buildMapButton(Icons.my_location, _centerOnUser, iconColor: Colors.blueAccent),
              ],
            ),
          ),

          // --- НОВАЯ НИЖНЯЯ ПАНЕЛЬ ТРЕКЕРА ---
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  // Виджет круглой кнопки (СТАРЫЙ ДИЗАЙН)
  Widget _buildMapButton(IconData icon, VoidCallback onTap, {bool isActive = false, Color iconColor = Colors.white}) {
    return FloatingActionButton.small(
      heroTag: icon.toString(),
      backgroundColor: AppTheme.cardDark.withOpacity(0.9),
      onPressed: onTap,
      child: Icon(icon, color: isActive ? AppTheme.accentYellow : iconColor),
    );
  }

  Widget _buildMapBody() {
    if (_isLoadingLocation) return const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow));
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)));

    final initialCenter = _currentLocation ?? const LatLng(43.2220, 76.8512);
    // ВЕРНУЛИ ТЕМНУЮ ТЕМУ КАРТЫ
    final String mapUrl = _isTopoMap
        ? 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png' // Топография
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';  // Обычная OSM

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: initialCenter, initialZoom: 16.0),
      children: [
        TileLayer(urlTemplate: mapUrl, userAgentPackageName: 'com.yourname.hikingapp'),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.redAccent), // СТАРАЯ КРАСНАЯ ЛИНИЯ
            ],
          ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(point: _currentLocation!, width: 60, height: 60, child: _buildUserMarker()), // СТАРЫЙ МАРКЕР
            ],
          ),
      ],
    );
  }

  Widget _buildUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.3), shape: BoxShape.circle)),
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: Colors.blueAccent, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
          ),
        ),
      ],
    );
  }

  // --- НОВАЯ НИЖНЯЯ ПАНЕЛЬ ИЗ FIGMA ---
  Widget _buildBottomPanel() {
    final double distanceKm = _distanceMeters / 1000;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111), // Глубокий черный
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        // Добавили легкую тень сверху, чтобы отделить от темной карты
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -5))],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ПОКАЗАТЕЛИ (Время, Дистанция, Высота)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(value: _formattedTime, unit: '', label: 'Time'),
              _buildStatItem(value: distanceKm.toStringAsFixed(2), unit: 'km', label: 'Distance'),
              _buildStatItem(value: _elevationGain.toStringAsFixed(0), unit: 'm', label: 'Elev. gain'),
            ],
          ),
          const SizedBox(height: 24),

          // КНОПКИ (Nearby / Start)
          Row(
            children: [
              const SizedBox(width: 12),
              // Кнопка Старт/Пауза
              Expanded(
                flex: 1,
                child: _buildMainActionButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton() {
    if (_trackingState == TrackingState.idle) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF88FF66), // Зеленый из макета
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        icon: const Icon(Icons.navigation_rounded, color: Colors.black, size: 20),
        label: const Text('Start Hiking', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: _startTracking,
      );
    }

    // Если трекинг идет -> показываем Pause и Stop
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              // На паузе кнопка становится зеленой, при активе - серой
              backgroundColor: _trackingState == TrackingState.active ? Colors.white24 : const Color(0xFF88FF66),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _trackingState == TrackingState.active ? _pauseTracking : _resumeTracking,
            // Иконка меняется (черная если фон зеленый, белая если фон серый)
            child: Icon(_trackingState == TrackingState.active ? Icons.pause : Icons.play_arrow, color: _trackingState == TrackingState.active ? Colors.white : Colors.black),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.3), // Красная, но полупрозрачная
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _stopTracking,
            child: const Icon(Icons.stop, color: Colors.redAccent),
          ),
        ),
      ],
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
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w500)),
            if (unit.isNotEmpty)
              Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
// lib/features/map/presentation/map_screen.dart
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../tracking/providers/tracking_provider.dart';
import '../../tracking/presentation/save_track_screen.dart';
import '../../routes/providers/route_provider.dart';
import '../../routes/data/models/route_model.dart';

enum MapStyle { topo, satellite }

class MapScreen extends StatefulWidget {
  final String? targetPeakName;
  const MapScreen({super.key, this.targetPeakName});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Dio _dio = Dio();

  // --- ЦВЕТА И СТИЛИ ИЗ ТВОЕГО ДИЗАЙНА ---
  final Color _routeGreen = const Color(0xFF32D74B);
  final Color _userBlue = const Color(0xFF007AFF);
  final Color _glassColor = Colors.black.withOpacity(0.4);
  final Color _glassBorder = Colors.white.withOpacity(0.15);

  MapStyle _currentMapStyle = MapStyle.topo;
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  bool _isPanelExpanded = false;

  final String _selectedActivity = 'Hiking';
  String _weatherText = 'Loading...';
  IconData _weatherIcon = Icons.cloud_outlined;

  // --- ДАННЫЕ О МАРШРУТЕ ---
  RouteModel? _selectedRoute;
  WaypointData? _selectedWaypoint; // Для желтых меток

  List<LatLng> _pathToPeak = []; // Линия "Как доехать" (OSRM)
  bool _isLoadingPath = false;

  @override
  void initState() {
    super.initState();
    _initLocation();

    // Авто-выбор горы, если перешли с экрана деталей
    if (widget.targetPeakName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _autoSelectRoute(widget.targetPeakName!);
        });
      });
    }
  }

  void _autoSelectRoute(String target) {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    try {
      final realTarget = target.split('||')[0];
      final route = routeProvider.routes.firstWhere((r) => r.name == realTarget || r.id == realTarget);
      _onRouteTapped(route);
    } catch (e) {
      debugPrint("Маршрут не найден.");
    }
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
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _fetchWeather(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // --- ПОГОДА ---
  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final response = await _dio.get('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      if (response.statusCode == 200) {
        final current = response.data['current_weather'];
        if (mounted) {
          setState(() {
            _weatherText = '${current['temperature'].round()}°C';
            _weatherIcon = _getWeatherIcon(current['weathercode']);
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _weatherText = '--');
    }
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.cloud_queue_rounded;
    if (code <= 67) return Icons.water_drop_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    return Icons.cloud_rounded;
  }

  // --- ПУТЬ ДО СТАРТА (OSRM API) ---
  Future<void> _fetchPathToRoute(RouteModel route) async {
    final tracker = Provider.of<TrackingProvider>(context, listen: false);
    final startPoint = tracker.currentLocation ?? _currentLocation;

    if (startPoint == null) return;

    setState(() { _isLoadingPath = true; _pathToPeak.clear(); });

    final destination = route.trailhead;

    try {
      // Используем маршрут driving, чтобы доехать до парковки/шлагбаума
      final url = 'https://router.project-osrm.org/route/v1/driving/${startPoint.longitude},${startPoint.latitude};${destination.longitude},${destination.latitude}?geometries=geojson';
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final coords = response.data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _pathToPeak = coords.map((c) => LatLng(c[1], c[0])).toList();
          _isLoadingPath = false;
        });
        // Красиво наезжаем камерой, чтобы было видно оба маршрута
        _mapController.fitCamera(
          CameraFit.bounds(bounds: LatLngBounds.fromPoints([startPoint, destination, ...route.trackPoints]), padding: const EdgeInsets.all(50.0)),
        );
      }
    } catch (e) {
      setState(() => _isLoadingPath = false);
    }
  }

  String get _mapUrlTemplate {
    if (_currentMapStyle == MapStyle.satellite) {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png'; // Отличная карта для гор
  }

  void _showMapStyleSelector(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text('Map Type', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.terrain_outlined, color: Colors.white),
                  title: const Text('Topographic Map', style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: _currentMapStyle == MapStyle.topo ? Icon(Icons.check_circle, color: _userBlue) : null,
                  onTap: () { setState(() => _currentMapStyle = MapStyle.topo); Navigator.pop(context); },
                ),
                ListTile(
                  leading: const Icon(Icons.satellite_alt_outlined, color: Colors.white),
                  title: const Text('Satellite', style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: _currentMapStyle == MapStyle.satellite ? Icon(Icons.check_circle, color: _userBlue) : null,
                  onTap: () { setState(() => _currentMapStyle = MapStyle.satellite); Navigator.pop(context); },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
    );
  }

  void _onRouteTapped(RouteModel route) {
    setState(() {
      _selectedRoute = route;
      _selectedWaypoint = null;
      _pathToPeak.clear(); // Очищаем старый путь доезда
    });

    if (route.trackPoints.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: LatLngBounds.fromPoints([route.trackPoints.first, route.trackPoints.last]), padding: const EdgeInsets.all(70.0)),
      );
    } else {
      _mapController.move(LatLng(route.latitude, route.longitude), 14.0);
    }
  }

  void _clearSelectedRoute() {
    setState(() {
      _selectedRoute = null;
      _selectedWaypoint = null;
      _pathToPeak.clear();
    });
  }

  void _zoomIn() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  void _zoomOut() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  void _moveToCurrentLocation() {
    final tracker = Provider.of<TrackingProvider>(context, listen: false);
    if (tracker.currentLocation != null) _mapController.move(tracker.currentLocation!, 16.0);
    else if (_currentLocation != null) _mapController.move(_currentLocation!, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildMap(context, tracker, routeProvider),

            // --- ЭЛЕМЕНТЫ УПРАВЛЕНИЯ КАРТОЙ (Из твоего дизайна) ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGlassButton(icon: Icons.keyboard_arrow_down_rounded, onTap: () => context.pop()),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGlassPanel(
                          child: IconButton(icon: const Icon(Icons.layers_rounded, color: Colors.white), onPressed: () => _showMapStyleSelector(context)),
                        ),
                        const SizedBox(height: 16),
                        _buildGlassPanel(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _zoomIn),
                              Container(height: 1, width: 24, color: Colors.white24),
                              IconButton(icon: const Icon(Icons.remove, color: Colors.white), onPressed: _zoomOut),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGlassButton(icon: Icons.my_location_rounded, onTap: _moveToCurrentLocation),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- КАРТОЧКА ФОТОГРАФИИ МЕТКИ ---
            if (_selectedWaypoint != null)
              Positioned(
                top: 100, left: 20, right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), border: Border.all(color: Colors.white24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(_selectedWaypoint!.imageUrl, height: 180, fit: BoxFit.cover),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedWaypoint!.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _selectedWaypoint = null))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // --- НИЖНЯЯ ПАНЕЛЬ С АНИМАЦИЕЙ ---
            if (_selectedWaypoint == null)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                  child: _getBottomPanelContent(tracker),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Логика выбора нижней панели
  Widget _getBottomPanelContent(TrackingProvider tracker) {
    if (tracker.status != TrackingStatus.idle) {
      // ИДЕТ ЗАПИСЬ (Свободная или по маршруту)
      return _buildRoutePanel(tracker, key: const ValueKey('tracking_panel'));
    } else if (_selectedRoute != null) {
      // ВЫБРАНА ГОРА, НО ЗАПИСЬ НЕ ИДЕТ
      return _buildMiniRouteInfo(tracker, key: const ValueKey('peak_info'));
    } else {
      // СВОБОДНЫЙ РЕЖИМ (Idle)
      return _buildRoutePanel(tracker, key: const ValueKey('free_idle_panel'));
    }
  }

  // --- МИНИ-КАРТОЧКА ГОРЫ ---
  Widget _buildMiniRouteInfo(TrackingProvider tracker, {required Key key}) {
    Color difficultyColor = _selectedRoute!.difficulty.toUpperCase() == 'HARD' ? const Color(0xFFFF453A) : _selectedRoute!.difficulty.toUpperCase() == 'EASY' ? const Color(0xFF32D74B) : const Color(0xFFFF9F0A);

    return ClipRRect(
      key: key,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.0))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(_selectedRoute!.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 28), onPressed: _clearSelectedRoute)
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.route_rounded, color: Colors.white54, size: 18),
                  const SizedBox(width: 4),
                  Text('${_selectedRoute!.distanceKm} km', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: difficultyColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(_selectedRoute!.difficulty.toUpperCase(), style: TextStyle(color: difficultyColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoadingPath)
                const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(color: Colors.white)))
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () => context.push('/routes/${_selectedRoute!.id}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_pathToPeak.isNotEmpty)
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: _routeGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text('Start Trek', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          onPressed: () {
                            tracker.startTracking(); // Начинаем запись Провайдером!
                          },
                        ),
                      )
                    else
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                          icon: const Icon(Icons.directions_car_rounded),
                          label: const Text('Draw Path', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          onPressed: () => _fetchPathToRoute(_selectedRoute!),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ГЛАВНАЯ ПАНЕЛЬ ТРЕКЕРА (Твой дизайн) ---
  Widget _buildRoutePanel(TrackingProvider tracker, {Key? key}) {
    return GestureDetector(
      key: key,
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5 && !_isPanelExpanded) setState(() => _isPanelExpanded = true);
        else if (details.delta.dy > 5 && _isPanelExpanded) setState(() => _isPanelExpanded = false);
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.0))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
                    child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20, top: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(3))),
                  ),
                ),

                // Раскрывающаяся инфа (Погода, активность)
                AnimatedCrossFade(
                  firstChild: const SizedBox(height: 8),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      children: [
                        _buildExtraInfoRow(Icons.directions_walk_rounded, 'Activity', _selectedActivity),
                        const SizedBox(height: 16),
                        _buildExtraInfoRow(_weatherIcon, 'Weather', _weatherText, showArrow: false),
                        const SizedBox(height: 20),
                        Divider(color: Colors.white.withOpacity(0.15)),
                      ],
                    ),
                  ),
                  crossFadeState: _isPanelExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),

                // Цифры трекера
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(value: tracker.status == TrackingStatus.idle ? "0:00" : tracker.formattedTime, unit: '', label: 'Time'),
                    _buildStatItem(value: tracker.totalDistanceKm.toStringAsFixed(2), unit: 'km', label: 'Distance'),
                    _buildStatItem(value: "--", unit: 'm', label: 'Elev. gain'), // Провайдер пока не считает высоту
                  ],
                ),
                const SizedBox(height: 32),

                // Кнопки управления (Start / Pause / Stop)
                _buildActionButtons(tracker),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraInfoRow(IconData icon, String title, String value, {bool showArrow = true}) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16))),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        if (showArrow) const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20) else const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildStatItem({required String value, required String unit, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -1)),
            if (unit.isNotEmpty) Text(' $unit', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionButtons(TrackingProvider tracker) {
    if (tracker.status == TrackingStatus.idle) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
          label: const Text('Start Free Tracking', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
          onPressed: () => tracker.startTracking(),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: tracker.isPaused ? Colors.white : Colors.white.withOpacity(0.15), foregroundColor: tracker.isPaused ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            icon: Icon(tracker.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(tracker.isPaused ? 'Resume' : 'Pause', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: tracker.isPaused ? () => tracker.resumeTracking() : () => tracker.pauseTracking(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF453A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
            ),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop & Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: () async {
              // 1. Ставим трекер на паузу
              tracker.pauseTracking();

              // 2. Открываем наш крутой экран сохранения
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SaveTrackScreen())
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _glassColor, border: Border.all(color: _glassBorder), borderRadius: BorderRadius.circular(24)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(decoration: BoxDecoration(color: _glassColor, border: Border.all(color: _glassBorder), borderRadius: BorderRadius.circular(24)), child: child),
      ),
    );
  }

  Widget _buildMap(BuildContext context, TrackingProvider tracker, RouteProvider routeProvider) {
    if (_isLoadingLocation) return const Center(child: CircularProgressIndicator(color: Colors.white));

    // Центр карты: если идет запись - следим за трекером, иначе за выбранной горой
    LatLng center = tracker.currentLocation ?? _currentLocation ?? const LatLng(43.1410, 77.0700);

    return GestureDetector(
      onTap: () { setState(() => _selectedWaypoint = null); },
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12.0,
          onTap: (_, __) => setState(() => _selectedWaypoint = null),
        ),
        children: [
          TileLayer(
            urlTemplate: _mapUrlTemplate,
            userAgentPackageName: 'com.hikingapp.kazakhstan',
            subdomains: const ['a', 'b', 'c'],

            maxNativeZoom: 17,
            maxZoom: 22,
          ),

          // 1. ЛИНИЯ ДОЕЗДА ДО СТАРТА (OSRM - Светло-синяя)
          if (_pathToPeak.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(points: _pathToPeak, strokeWidth: 4.0, color: Colors.lightBlueAccent.withOpacity(0.9), borderStrokeWidth: 1.5, borderColor: Colors.blue[900]!)
              ],
            ),

          // 2. ЗЕЛЕНАЯ ТРОПА ГОРЫ (GPX)
          if (_selectedRoute != null && _selectedRoute!.trackPoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(points: _selectedRoute!.trackPoints, strokeWidth: 5.0, color: _routeGreen, borderStrokeWidth: 2.0, borderColor: Colors.black87)
              ],
            ),

          // 3. ТВОЙ ТЕКУЩИЙ МАРШРУТ ЗАПИСИ (Синий)
          if (tracker.routePoints.isNotEmpty)
            PolylineLayer(polylines: [Polyline(points: tracker.routePoints, strokeWidth: 6.0, color: _userBlue, borderStrokeWidth: 1.5, borderColor: Colors.white)]),

          MarkerLayer(
            markers: [
              // Моя локация
              if (tracker.currentLocation != null || _currentLocation != null)
                Marker(
                  point: tracker.currentLocation ?? _currentLocation!, width: 24, height: 24,
                  child: Container(decoration: BoxDecoration(color: _userBlue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)])),
                ),

              // Иконки всех гор из БД
              ...routeProvider.routes.map((route) {
                bool isSelected = _selectedRoute?.id == route.id;
                return Marker(
                  point: LatLng(route.latitude, route.longitude),
                  width: 40, height: 40, alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _onRouteTapped(route),
                    child: Container(
                      decoration: BoxDecoration(color: isSelected ? const Color(0xFFFF453A) : Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)]),
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.terrain_rounded, color: isSelected ? Colors.white : const Color(0xFFFF453A), size: 24),
                    ),
                  ),
                );
              }),

              // Зеленый флаг на старте + Желтые метки
              if (_selectedRoute != null && _selectedRoute!.trackPoints.isNotEmpty) ...[
                Marker(
                  point: _selectedRoute!.trackPoints.first,
                  width: 40, height: 40, alignment: Alignment.topCenter,
                  child: Container(decoration: const BoxDecoration(color: Color(0xFF32D74B), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)]), padding: const EdgeInsets.all(4), child: const Icon(Icons.flag_circle_rounded, color: Colors.white, size: 24)),
                ),
                ..._selectedRoute!.waypoints.map((wp) {
                  bool isSelected = _selectedWaypoint == wp;
                  return Marker(
                    point: wp.location,
                    width: isSelected ? 40 : 30, height: isSelected ? 40 : 30, alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () { setState(() => _selectedWaypoint = wp); _mapController.move(wp.location, 16.0); },
                      child: Icon(Icons.location_on_rounded, color: isSelected ? Colors.yellowAccent : Colors.orangeAccent, size: isSelected ? 40 : 30, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]),
                    ),
                  );
                }),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
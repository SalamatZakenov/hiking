// lib/features/map/presentation/map_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../tracking/providers/tracking_provider.dart';
import '../../routes/providers/route_provider.dart';
import '../../routes/data/models/route_model.dart';

enum MapStyle { satellite, tourist }

class MapScreen extends StatefulWidget {
  final String? targetPeakName;
  const MapScreen({super.key, this.targetPeakName});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  MapStyle _currentMapStyle = MapStyle.tourist;
  LatLng? _localLocation;

  RouteModel? _selectedRoute;
  WaypointData? _selectedWaypoint;

  bool _isPanelVisible = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (mounted) setState(() => _localLocation = LatLng(position.latitude, position.longitude));
    } catch (e) {}
  }

  String get _mapUrlTemplate {
    if (_currentMapStyle == MapStyle.satellite) {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  }

  void _onRouteTapped(RouteModel route) {
    setState(() {
      _selectedRoute = route;
      _selectedWaypoint = null;
      _isPanelVisible = true;
    });

    if (route.trackPoints.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([route.trackPoints.first, route.trackPoints.last]),
            padding: const EdgeInsets.all(70.0)
        ),
      );
    } else {
      _mapController.move(LatLng(route.latitude, route.longitude), 14.0);
    }
  }

  void _closePanel() {
    setState(() {
      _isPanelVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. КАРТА
          GestureDetector(
            onTap: () {
              setState(() => _selectedWaypoint = null);
              if (_isPanelVisible) _closePanel();
            },
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(43.1410, 77.0700),
                initialZoom: 12.0,
                onTap: (_, __) {
                  setState(() => _selectedWaypoint = null);
                  if (_isPanelVisible) _closePanel();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _mapUrlTemplate,
                  userAgentPackageName: 'com.hikingapp.kazakhstan',
                  subdomains: const ['a', 'b', 'c'],
                ),

                // ЗЕЛЕНАЯ ТРОПА
                if (_selectedRoute != null && _selectedRoute!.trackPoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: _selectedRoute!.trackPoints, strokeWidth: 5.0, color: const Color(0xFF32D74B), borderStrokeWidth: 2.0, borderColor: Colors.black87)
                    ],
                  ),

                if (tracker.routePoints.isNotEmpty)
                  PolylineLayer(polylines: [Polyline(points: tracker.routePoints, strokeWidth: 6.0, color: Colors.blueAccent)]),

                MarkerLayer(
                  markers: [
                    // --- ВСЕ ГОРЫ ИЗ БАЗЫ ДАННЫХ ---
                    ...routeProvider.routes.map((route) {
                      bool isSelected = _selectedRoute?.id == route.id;
                      return Marker(
                        point: LatLng(route.latitude, route.longitude),
                        width: 40, height: 40, alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => _onRouteTapped(route),
                          child: Container(
                            decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF453A) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)]
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.terrain_rounded, color: isSelected ? Colors.white : const Color(0xFFFF453A), size: 24),
                          ),
                        ),
                      );
                    }),

                    // --- СТАРТ И МЕТКИ (Только для выбранной горы) ---
                    if (_selectedRoute != null && _selectedRoute!.trackPoints.isNotEmpty) ...[
                      Marker(
                        point: _selectedRoute!.trackPoints.first,
                        width: 40, height: 40, alignment: Alignment.topCenter,
                        child: Container(
                          decoration: const BoxDecoration(color: Color(0xFF32D74B), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)]),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.flag_circle_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      ..._selectedRoute!.waypoints.map((wp) {
                        bool isSelected = _selectedWaypoint == wp;
                        return Marker(
                          point: wp.location,
                          width: isSelected ? 40 : 30, height: isSelected ? 40 : 30,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedWaypoint = wp);
                              _mapController.move(wp.location, 16.0);
                            },
                            child: Icon(Icons.location_on_rounded, color: isSelected ? Colors.yellowAccent : Colors.orangeAccent, size: isSelected ? 40 : 30, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]),
                          ),
                        );
                      }),
                    ],

                    if (tracker.currentLocation != null)
                      Marker(
                        point: tracker.currentLocation!, width: 24, height: 24,
                        child: Container(decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3))),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // --- КНОПКА "НАЗАД" (Слева сверху) ---
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMapBtn(
                  Icons.arrow_back_ios_new_rounded,
                      () => context.pop(), // Закрывает карту и возвращает на прошлый экран
                ),
              ),
            ),
          ),

          // --- КНОПКИ СПРАВА СВЕРХУ ---
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMapBtn(
                        _currentMapStyle == MapStyle.tourist ? Icons.layers_outlined : Icons.satellite_alt_rounded,
                            () => setState(() => _currentMapStyle = _currentMapStyle == MapStyle.tourist ? MapStyle.satellite : MapStyle.tourist)
                    ),
                    const SizedBox(height: 12),
                    _buildMapBtn(Icons.my_location, () { if (tracker.currentLocation != null) _mapController.move(tracker.currentLocation!, 15); }),
                  ],
                ),
              ),
            ),
          ),

          // --- ВСПЛЫВАЮЩАЯ КАРТОЧКА ФОТО ---
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

          // --- АНИМИРОВАННАЯ ШТОРКА ---
          if (_selectedWaypoint == null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: 0, right: 0,
              bottom: (_selectedRoute != null && _isPanelVisible) ? 0 : -300,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 5) _closePanel();
                },
                child: _buildPeakInfoPanel(tracker),
              ),
            ),

          // Панель трекинга
          if (tracker.status != TrackingStatus.idle && _selectedWaypoint == null)
            Positioned(left: 0, right: 0, bottom: 0, child: _buildTrackingPanel(tracker)),
        ],
      ),
    );
  }

  Widget _buildPeakInfoPanel(TrackingProvider tracker) {
    if (_selectedRoute == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(10)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_selectedRoute!.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 30), onPressed: _closePanel)
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                  label: const Text('Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    context.push('/routes/${_selectedRoute!.id}');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF32D74B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Start Trek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    tracker.startTracking();
                    _closePanel();
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrackingPanel(TrackingProvider tracker) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [const Text('TIME', style: TextStyle(color: Colors.white54)), Text(tracker.formattedTime, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))]),
              Column(children: [const Text('DISTANCE', style: TextStyle(color: Colors.white54)), Text('${tracker.totalDistanceKm.toStringAsFixed(2)} km', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))]),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.white12, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () => tracker.isPaused ? tracker.resumeTracking() : tracker.pauseTracking(), child: Text(tracker.isPaused ? 'Resume' : 'Pause', style: const TextStyle(fontSize: 16)))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF453A), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () async { await tracker.stopTracking(); }, child: const Text('Stop', style: TextStyle(fontSize: 16)))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 45, height: 45,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white)
      ),
    );
  }
}
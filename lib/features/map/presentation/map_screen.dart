// lib/features/map/presentation/map_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Dio _dio = Dio();

  final Color _routeGreen = const Color(0xFF00E5FF);
  final Color _userBlue = const Color(0xFF007AFF);
  final Color _glassColor = Colors.black.withOpacity(0.4);
  final Color _glassBorder = Colors.white.withOpacity(0.15);

  MapStyle _currentMapStyle = MapStyle.topo;
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  bool _isPanelExpanded = false;

  bool _autoFollow = true;

  final String _selectedActivity = 'Hiking';
  String _weatherText = 'Loading...';
  IconData _weatherIcon = Icons.cloud_outlined;

  RouteModel? _selectedRoute;
  WaypointData? _selectedWaypoint;
  bool _isPanelVisible = false;
  List<LatLng> _pathToPeak = [];
  bool _isLoadingPath = false;
  bool _isInitializingTarget = false;

  @override
  void initState() {
    super.initState();
    _initLocation();

    if (widget.targetPeakName != null) {
      _isInitializingTarget = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSelectRoute(widget.targetPeakName!);
      });
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _animatedFitCamera(LatLngBounds bounds, EdgeInsets padding) {
    try {
      final target = CameraFit.bounds(bounds: bounds, padding: padding).fit(_mapController.camera);
      _animatedMapMove(target.center, target.zoom);
    } catch (e) {
      _animatedMapMove(bounds.center, 14.0);
    }
  }

  Future<void> _autoSelectRoute(String target) async {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    if (routeProvider.routes.isEmpty) await routeProvider.fetchRoutes();

    try {
      final realTarget = target.split('||')[0];
      final route = routeProvider.routes.firstWhere((r) => r.name == realTarget || r.id == realTarget);
      await routeProvider.loadGpxForRoute(route.id);

      if (mounted) {
        setState(() {
          _selectedRoute = routeProvider.findById(route.id);
          _selectedWaypoint = null;
          _isPanelVisible = true;
          _pathToPeak.clear();
          _isInitializingTarget = false;
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted || _selectedRoute == null) return;
          if (_selectedRoute!.trackPoints.isNotEmpty) {
            _animatedFitCamera(
                LatLngBounds.fromPoints(_selectedRoute!.trackPoints),
                const EdgeInsets.only(left: 50.0, right: 50.0, top: 50.0, bottom: 350.0)
            );
          } else {
            _animatedMapMove(LatLng(route.latitude, route.longitude), 14.0);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitializingTarget = false);
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

  // ОБНОВЛЕННЫЙ МЕТОД: Строит путь именно до ПЕРВОГО маркера (или старта трека)
  Future<void> _fetchPathToRoute(RouteModel route) async {
    final tracker = Provider.of<TrackingProvider>(context, listen: false);
    final startPoint = tracker.currentLocation ?? _currentLocation;
    if (startPoint == null) return;

    setState(() { _isLoadingPath = true; _pathToPeak.clear(); });

    // Находим точную точку старта из файла
    LatLng destination;
    if (route.waypoints.isNotEmpty) {
      destination = route.waypoints.first.location; // Самая первая метка (например, Шлагбаум)
    } else if (route.trackPoints.isNotEmpty) {
      destination = route.trackPoints.first; // Первая точка самого пути
    } else {
      destination = LatLng(route.latitude, route.longitude); // Резервный вариант
    }

    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/${startPoint.longitude},${startPoint.latitude};${destination.longitude},${destination.latitude}?geometries=geojson';
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final coords = response.data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _pathToPeak = coords.map((c) => LatLng(c[1], c[0])).toList();
          _isLoadingPath = false;
        });
        _animatedFitCamera(
            LatLngBounds.fromPoints([startPoint, destination, ...route.trackPoints]),
            const EdgeInsets.only(left: 50.0, right: 50.0, top: 50.0, bottom: 350.0)
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
    return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  }

  void _showMapStyleSelector(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return SafeArea(
            child: Consumer<RouteProvider>(
                builder: (context, provider, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 24),
                        const Text('Map Layer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.terrain_outlined, color: Colors.white),
                          title: const Text('Topographic Map', style: TextStyle(color: Colors.white, fontSize: 16)),
                          trailing: _currentMapStyle == MapStyle.topo ? Icon(Icons.check_circle, color: _userBlue) : null,
                          onTap: () { setState(() => _currentMapStyle = MapStyle.topo); Navigator.pop(context); },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.satellite_alt_outlined, color: Colors.white),
                          title: const Text('Satellite', style: TextStyle(color: Colors.white, fontSize: 16)),
                          trailing: _currentMapStyle == MapStyle.satellite ? Icon(Icons.check_circle, color: _userBlue) : null,
                          onTap: () { setState(() => _currentMapStyle = MapStyle.satellite); Navigator.pop(context); },
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.white12)),
                        const Text('Offline Maps', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: provider.isRegionDownloaded ? _routeGreen.withOpacity(0.5) : Colors.white12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.map_rounded, color: Colors.white, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Almaty Mountains', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text(provider.isRegionDownloaded ? 'Available Offline' : '≈ 45 MB • Map & Routes', style: TextStyle(color: provider.isRegionDownloaded ? _routeGreen : Colors.white54, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  if (provider.isRegionDownloaded)
                                    Icon(Icons.check_circle_rounded, color: _routeGreen, size: 28)
                                  else if (!provider.isDownloadingRegion)
                                    IconButton(icon: const Icon(Icons.download_rounded, color: Colors.white), onPressed: () => provider.downloadAlmatyRegion())
                                ],
                              ),
                              if (provider.isDownloadingRegion) ...[
                                const SizedBox(height: 16),
                                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: provider.downloadProgress, backgroundColor: Colors.white12, color: _routeGreen, minHeight: 8)),
                                const SizedBox(height: 8),
                                Center(child: Text('${(provider.downloadProgress * 100).toInt()}% downloading...', style: const TextStyle(color: Colors.white54, fontSize: 12))),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                }
            ),
          );
        }
    );
  }

  void _onRouteTapped(RouteModel route) async {
    setState(() {
      _selectedRoute = route;
      _selectedWaypoint = null;
      _isPanelVisible = true;
      _pathToPeak.clear();
    });
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    await routeProvider.loadGpxForRoute(route.id);
    if (mounted) {
      setState(() { _selectedRoute = routeProvider.findById(route.id); });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted || _selectedRoute == null) return;
        if (_selectedRoute!.trackPoints.isNotEmpty) {
          _animatedFitCamera(LatLngBounds.fromPoints(_selectedRoute!.trackPoints), const EdgeInsets.only(left: 50.0, right: 50.0, top: 50.0, bottom: 350.0));
        } else {
          _animatedMapMove(LatLng(route.latitude, route.longitude), 14.0);
        }
      });
    }
  }

  void _closePanel() { setState(() { _isPanelVisible = false; _selectedRoute = null; _selectedWaypoint = null; _pathToPeak.clear(); }); }
  void _zoomIn() => _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  void _zoomOut() => _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  void _moveToCurrentLocation() { setState(() => _autoFollow = true); final tracker = Provider.of<TrackingProvider>(context, listen: false); if (tracker.currentLocation != null) _animatedMapMove(tracker.currentLocation!, 16.0); else if (_currentLocation != null) _animatedMapMove(_currentLocation!, 16.0); }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);

    if (tracker.isTracking && tracker.currentLocation != null && _autoFollow) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _mapController.move(tracker.currentLocation!, _mapController.camera.zoom); });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildMap(context, tracker, routeProvider),
            if (_isInitializingTarget) Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7), child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))))),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildGlassButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGlassPanel(child: IconButton(icon: const Icon(Icons.layers_rounded, color: Colors.white), onPressed: () => _showMapStyleSelector(context))),
                      const SizedBox(height: 16),
                      _buildGlassPanel(child: Column(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _zoomIn), Container(height: 1, width: 24, color: Colors.white24), IconButton(icon: const Icon(Icons.remove, color: Colors.white), onPressed: _zoomOut)])),
                      const SizedBox(height: 16),
                      _buildGlassButton(icon: Icons.my_location_rounded, onTap: _moveToCurrentLocation, iconColor: _autoFollow && tracker.isTracking ? const Color(0xFF00E5FF) : Colors.white),
                    ],
                  ),
                ),
              ),
            ),
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
                          CachedNetworkImage(imageUrl: _selectedWaypoint!.imageUrl, height: 180, fit: BoxFit.cover),
                          Padding(padding: const EdgeInsets.all(16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_selectedWaypoint!.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _selectedWaypoint = null))]))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_selectedWaypoint == null)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) { if (details.primaryDelta! > 5 && tracker.status == TrackingStatus.idle && _selectedRoute != null) _closePanel(); },
                  child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic, child: _getBottomPanelContent(tracker)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context, TrackingProvider tracker, RouteProvider routeProvider) {
    LatLng center = tracker.currentLocation ?? _currentLocation ?? const LatLng(43.1410, 77.0700);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedWaypoint = null);
        if (_isPanelVisible && tracker.status == TrackingStatus.idle) _closePanel();
      },
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12.0,
          onTap: (_, __) {
            setState(() => _selectedWaypoint = null);
            if (_isPanelVisible && tracker.status == TrackingStatus.idle) _closePanel();
          },
          onPositionChanged: (position, hasGesture) {
            if (hasGesture && _autoFollow) {
              setState(() => _autoFollow = false);
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: _mapUrlTemplate,
            userAgentPackageName: 'com.hikingapp.kazakhstan',
            subdomains: const ['a', 'b', 'c'],
            maxNativeZoom: 17,
            maxZoom: 22,
            tileProvider: CachedTileProvider(),
          ),

          // ВЫДЕЛЕННЫЙ ПУТЬ ДО СТАРТА (Оранжево-желтый)
          if (_pathToPeak.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                    points: _pathToPeak,
                    strokeWidth: 4.0,
                    color: Colors.amber, // Выделяем путь до начала ярким цветом
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.black87
                )
              ],
            ),

          if (_selectedRoute != null && _selectedRoute!.trackPoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(points: _selectedRoute!.trackPoints, strokeWidth: 5.0, color: _routeGreen, borderStrokeWidth: 2.0, borderColor: Colors.black87)
              ],
            ),

          if (tracker.routePoints.isNotEmpty)
            PolylineLayer(polylines: [Polyline(points: tracker.routePoints, strokeWidth: 6.0, color: _userBlue, borderStrokeWidth: 1.5, borderColor: Colors.white)]),

          MarkerLayer(
            markers: [
              if (tracker.currentLocation != null || _currentLocation != null)
                Marker(
                  point: tracker.currentLocation ?? _currentLocation!, width: 24, height: 24,
                  child: Container(decoration: BoxDecoration(color: _userBlue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)])),
                ),

              ...routeProvider.routes.where((r) => r.latitude != 0.0 || r.trackPoints.isNotEmpty).map((route) {
                bool isSelected = _selectedRoute?.id == route.id;
                LatLng markerPos = (route.trackPoints.isNotEmpty) ? route.trackPoints.last : LatLng(route.latitude, route.longitude);

                return Marker(
                  point: markerPos,
                  width: 50, height: 50, alignment: Alignment.topCenter,
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

              if (_selectedRoute != null && _selectedRoute!.trackPoints.isNotEmpty) ...[
                Marker(
                  point: _selectedRoute!.trackPoints.first,
                  width: 40, height: 40, alignment: Alignment.topCenter,
                  child: Container(decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)]), padding: const EdgeInsets.all(4), child: const Icon(Icons.flag_circle_rounded, color: Colors.white, size: 24)),
                ),
                ..._selectedRoute!.waypoints.map((wp) {
                  bool isSelected = _selectedWaypoint == wp;
                  return Marker(
                    point: wp.location,
                    width: isSelected ? 40 : 30, height: isSelected ? 40 : 30, alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedWaypoint = wp);
                        _animatedMapMove(wp.location, 16.0);
                      },
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

  Widget _getBottomPanelContent(TrackingProvider tracker) {
    if (tracker.status != TrackingStatus.idle) {
      return _buildTrackingPanel(tracker, key: const ValueKey('tracking_panel'));
    } else if (_selectedRoute != null && _isPanelVisible) {
      return _buildMiniRouteInfo(tracker, key: const ValueKey('route_info_panel'));
    } else {
      return _buildFreeTrackingPanel(tracker, key: const ValueKey('free_roam_panel'));
    }
  }

  Widget _buildFreeTrackingPanel(TrackingProvider tracker, {Key? key}) {
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
                  const Text('Record Activity', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                          children: const [
                            Icon(Icons.directions_walk_rounded, color: Color(0xFF00E5FF), size: 18),
                            SizedBox(width: 6),
                            Text('Hiking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ]
                      )
                  )
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text('Start Recording', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  onPressed: () {
                    setState(() => _autoFollow = true);
                    tracker.startTracking();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniRouteInfo(TrackingProvider tracker, {Key? key}) {
    Color difficultyColor = _selectedRoute!.difficulty.toUpperCase() == 'HARD' ? const Color(0xFFFF453A) : _selectedRoute!.difficulty.toUpperCase() == 'EASY' ? const Color(0xFF00E5FF) : const Color(0xFFFF9F0A);

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
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 28), onPressed: _closePanel)
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
                    SizedBox(
                      width: 60, height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Icon(Icons.info_outline_rounded),
                        onPressed: () => context.push('/routes/${_selectedRoute!.id}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_pathToPeak.isEmpty) ...[
                      SizedBox(
                        width: 60, height: 58,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          child: const Icon(Icons.directions_car_rounded),
                          onPressed: () => _fetchPathToRoute(_selectedRoute!),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 58,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: _routeGreen, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Trek', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          onPressed: () {
                            setState(() => _autoFollow = true);
                            tracker.startTracking();
                          },
                        ),
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

  Widget _buildTrackingPanel(TrackingProvider tracker, {Key? key}) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(value: tracker.status == TrackingStatus.idle ? "0:00" : tracker.formattedTime, unit: '', label: 'Time'),
                    _buildStatItem(value: tracker.totalDistanceKm.toStringAsFixed(2), unit: 'km', label: 'Distance'),
                    _buildStatItem(value: "--", unit: 'm', label: 'Elev. gain'),
                  ],
                ),
                const SizedBox(height: 32),
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
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: tracker.isPaused ? Colors.white : Colors.white.withOpacity(0.15), foregroundColor: tracker.isPaused ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            icon: Icon(tracker.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(tracker.isPaused ? 'Resume' : 'Pause', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: tracker.isPaused ? () {
              setState(() => _autoFollow = true);
              tracker.resumeTracking();
            } : () => tracker.pauseTracking(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF453A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop & Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: () async {
              tracker.pauseTracking();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SaveTrackScreen()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _glassColor, border: Border.all(color: _glassBorder), borderRadius: BorderRadius.circular(24)),
            child: Icon(icon, color: iconColor, size: 28),
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
}

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(getTileUrl(coordinates, options));
  }
}
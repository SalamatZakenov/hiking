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

enum TrackingState { idle, active, paused }

class Peak {
  final String id;
  final String name;
  final LatLng location;
  final int elevation;
  final String difficulty;

  Peak({required this.id, required this.name, required this.location, required this.elevation, required this.difficulty});
}

class MapScreen extends StatefulWidget {
  final String? targetPeakName;
  const MapScreen({super.key, this.targetPeakName});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Dio _dio = Dio();

  final Color _routeGreen = const Color(0xFF32D74B); // iOS Green
  final Color _userBlue = const Color(0xFF007AFF); // iOS Blue
  final Color _glassColor = Colors.black.withOpacity(0.4);
  final Color _glassBorder = Colors.white.withOpacity(0.15);

  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  bool _isPanelExpanded = false;

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

  Peak? _selectedPeak;
  List<LatLng> _pathToPeak = [];
  bool _isLoadingPath = false;

  // --- НАВИГАЦИЯ ---
  bool _isNavigatingRoute = false;
  List<dynamic> _routeSteps = [];
  int _currentStepIndex = 0;

  final List<Peak> _peaks = [
    Peak(id: 'kok_tobe', name: 'Kok Tobe', location: const LatLng(43.2328, 76.9727), elevation: 1100, difficulty: 'EASY'),
    Peak(id: 'shymbulak', name: 'Shymbulak', location: const LatLng(43.1283, 77.0806), elevation: 2260, difficulty: 'MIDDLE'),
    Peak(id: 'bap', name: 'Big Almaty Peak', location: const LatLng(43.0601, 76.9333), elevation: 3680, difficulty: 'HARD'),
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
    if (widget.targetPeakName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _processTargetPeak(widget.targetPeakName!);
        });
      });
    }
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetPeakName != null && widget.targetPeakName != oldWidget.targetPeakName) {
      _processTargetPeak(widget.targetPeakName!);
    }
  }

  void _processTargetPeak(String uniqueTarget) {
    final realName = uniqueTarget.split('||')[0];
    try {
      final peak = _peaks.firstWhere((p) => p.name == realName);
      _onPeakTapped(peak);
    } catch (e) {
      // Игнорируем
    }
  }

  void _onPeakTapped(Peak peak) {
    setState(() {
      _selectedPeak = peak;
      _pathToPeak.clear();
      _routeSteps.clear();
      _isLoadingPath = false;
    });
    _mapController.move(peak.location, 14.0);
  }

  // Запрашиваем маршрут с ИНСТРУКЦИЯМИ ПОВОРОТОВ (steps=true)
  Future<void> _fetchPathToPeak(Peak peak) async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoadingPath = true;
      _pathToPeak.clear();
      _routeSteps.clear();
    });

    try {
      final url = 'http://router.project-osrm.org/route/v1/foot/${_currentLocation!.longitude},${_currentLocation!.latitude};${peak.location.longitude},${peak.location.latitude}?overview=full&geometries=geojson&steps=true';

      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final coords = response.data['routes'][0]['geometry']['coordinates'] as List;
        final steps = response.data['routes'][0]['legs'][0]['steps'] as List; // Шаги навигации

        setState(() {
          _pathToPeak = coords.map((c) => LatLng(c[1], c[0])).toList();
          _routeSteps = steps;
          _currentStepIndex = 0;
          _isLoadingPath = false;
        });

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([_currentLocation!, peak.location]),
            padding: const EdgeInsets.all(50.0),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _pathToPeak = [_currentLocation!, peak.location];
        _isLoadingPath = false;
      });
    }
  }

  // --- СТАРТ НАВИГАЦИИ ---
  void _startNavigation() {
    setState(() {
      _isNavigatingRoute = true;
      _selectedPeak = null; // Скрываем карточку пика, показываем панель трекинга
    });
    _mapController.move(_currentLocation!, 17.0); // Приближаем карту
    _startTracking(); // Запускаем сам таймер и трекинг
  }

  void _clearSelectedPeak() {
    setState(() {
      _selectedPeak = null;
      if (!_isNavigatingRoute) {
        _pathToPeak.clear();
        _routeSteps.clear();
      }
    });
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
      _fetchWeather(position.latitude, position.longitude);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final response = await _dio.get('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      if (response.statusCode == 200) {
        final current = response.data['current_weather'];
        setState(() {
          _weatherText = '${current['temperature'].round()}°C';
          _weatherIcon = _getWeatherIcon(current['weathercode']);
        });
      }
    } catch (e) {
      setState(() => _weatherText = '--');
    }
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.cloud_queue_rounded;
    if (code <= 67) return Icons.water_drop_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    return Icons.cloud_rounded;
  }

  // --- ТРЕКИНГ И ПРОВЕРКА ШАГОВ НАВИГАЦИИ ---
  void _startTracking() {
    setState(() {
      _trackingState = TrackingState.active;
      _isPanelExpanded = false;
      if (!_isNavigatingRoute) _secondsElapsed = 0; // Сбрасываем только если это новый свободный трекинг
      if (!_isNavigatingRoute) _distanceMeters = 0.0;
      if (!_isNavigatingRoute) _routePoints.clear();
      if (_currentLocation != null && _routePoints.isEmpty) _routePoints.add(_currentLocation!);
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

          // Проверяем, не дошли ли мы до следующего поворота?
          if (_isNavigatingRoute && _routeSteps.isNotEmpty && _currentStepIndex < _routeSteps.length) {
            final stepLoc = _routeSteps[_currentStepIndex]['maneuver']['location'];
            final stepLatLng = LatLng(stepLoc[1], stepLoc[0]);
            final distanceToTurn = const Distance().distance(newPoint, stepLatLng);

            // Если до поворота меньше 15 метров, переключаем на следующую инструкцию
            if (distanceToTurn < 15) {
              _currentStepIndex++;
            }
          }
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
      _isNavigatingRoute = false; // Выключаем режим навигации
      _pathToPeak.clear();
      _routeSteps.clear();
      _routePoints.clear();
      _secondsElapsed = 0;
      _distanceMeters = 0;
    });
    _positionStream?.cancel();
  }

  void _zoomIn() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  void _zoomOut() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  void _moveToCurrentLocation() {
    if (_currentLocation != null) _mapController.move(_currentLocation!, 16.0);
  }

  String get _formattedTime {
    final h = _secondsElapsed ~/ 3600;
    final m = (_secondsElapsed % 3600) ~/ 60;
    final s = _secondsElapsed % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // --- ГЕНЕРАТОР ТЕКСТА И ИКОНКИ ДЛЯ ПОВОРОТОВ ---
  String get _currentInstruction {
    if (!_isNavigatingRoute || _routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) return 'Follow the route to destination';
    final step = _routeSteps[_currentStepIndex];
    final type = step['maneuver']['type'];
    final modifier = step['maneuver']['modifier'] ?? '';
    final name = step['name'] ?? '';
    final distance = step['distance']?.toInt() ?? 0;

    String action = 'Go straight';
    if (type == 'turn') action = 'Turn $modifier';
    else if (type == 'arrive') action = 'Arrive at destination';

    String text = action;
    if (name.isNotEmpty) text += ' on $name';
    if (distance > 0) text += ' in ${distance}m';

    // Делаем текст красивым
    return text.replaceAll('left', 'left').replaceAll('right', 'right').capitalize();
  }

  IconData get _currentInstructionIcon {
    if (!_isNavigatingRoute || _routeSteps.isEmpty || _currentStepIndex >= _routeSteps.length) return Icons.navigation_rounded;
    final modifier = _routeSteps[_currentStepIndex]['maneuver']['modifier'] ?? '';
    if (modifier.contains('right')) return Icons.turn_right_rounded;
    if (modifier.contains('left')) return Icons.turn_left_rounded;
    if (modifier.contains('uturn')) return Icons.u_turn_left_rounded;
    return Icons.straight_rounded;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.black,
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
                    _buildGlassButton(icon: Icons.keyboard_arrow_down_rounded, onTap: () => context.go('/routes')),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGlassPanel(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.layers_rounded, color: Colors.white), onPressed: () {}),
                              Container(height: 1, width: 24, color: Colors.white24),
                              IconButton(icon: const Icon(Icons.view_in_ar_rounded, color: Colors.white), onPressed: () {}),
                            ],
                          ),
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

            Positioned(
              left: 0, right: 0, bottom: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
                  child: child,
                ),
                child: _selectedPeak != null
                    ? _buildMiniPeakInfo(key: const ValueKey('peak_info'))
                    : _buildRoutePanel(key: const ValueKey('route_panel')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPeakInfo({required Key key}) {
    Color difficultyColor = _selectedPeak!.difficulty == 'HARD' ? const Color(0xFFFF453A) : _selectedPeak!.difficulty == 'EASY' ? const Color(0xFF32D74B) : const Color(0xFFFF9F0A);

    return ClipRRect(
      key: key,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(_selectedPeak!.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 28), onPressed: _clearSelectedPeak)
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.height_rounded, color: Colors.white54, size: 18),
                  const SizedBox(width: 4),
                  Text('${_selectedPeak!.elevation}m', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: difficultyColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(_selectedPeak!.difficulty, style: TextStyle(color: difficultyColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15), foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                        ),
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () => context.push('/routes/${_selectedPeak!.id}'),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // --- МАГИЯ КНОПОК ЗДЕСЬ ---
                    // Если путь прорисован — показываем зеленую Start Route, иначе белую Draw Path
                    if (_pathToPeak.isNotEmpty)
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: _routeGreen, // Зеленая!
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                          ),
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text('Start Route', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          onPressed: _startNavigation, // Начинает навигацию!
                        ),
                      )
                    else
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.white, foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                          ),
                          icon: const Icon(Icons.directions_walk_rounded),
                          label: const Text('Draw Path', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          onPressed: () => _fetchPathToPeak(_selectedPeak!),
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
        child: Container(
          decoration: BoxDecoration(color: _glassColor, border: Border.all(color: _glassBorder), borderRadius: BorderRadius.circular(24)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoadingLocation) return const Center(child: CircularProgressIndicator(color: Colors.white));
    final initialCenter = _currentLocation ?? const LatLng(43.2300, 76.8520);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: initialCenter, initialZoom: 12.0),
      children: [
        TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', userAgentPackageName: 'com.yourname.hikingapp'),
        if (_pathToPeak.isNotEmpty)
          PolylineLayer(polylines: [Polyline(points: _pathToPeak, strokeWidth: 4.0, color: _userBlue, borderStrokeWidth: 1.0, borderColor: Colors.white)]),
        if (_routePoints.isNotEmpty)
          PolylineLayer(polylines: [Polyline(points: _routePoints, strokeWidth: 6.0, color: _routeGreen, borderStrokeWidth: 1.5, borderColor: Colors.black.withOpacity(0.3))]),
        MarkerLayer(
          markers: [
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!, width: 30, height: 30,
                child: Container(
                  decoration: BoxDecoration(color: _userBlue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
                ),
              ),
            ..._peaks.map((peak) {
              bool isSelected = _selectedPeak == peak;
              return Marker(
                point: peak.location, width: 40, height: 40,
                child: GestureDetector(
                  onTap: () => _onPeakTapped(peak),
                  child: AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0, duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(color: isSelected ? const Color(0xFFFF453A) : Colors.black87, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
                      child: const Icon(Icons.terrain_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutePanel({Key? key}) {
    final double displayDistanceKm = _distanceMeters / 1000;

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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.0))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
                    child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20, top: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(3))),
                  ),
                ),

                // --- БАННЕР НАВИГАЦИИ ПОЯВЛЯЕТСЯ ТУТ ---
                if (_isNavigatingRoute)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _userBlue.withOpacity(0.2), // Синий фон навигации
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _userBlue.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: _userBlue, shape: BoxShape.circle),
                          child: Icon(_currentInstructionIcon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(_currentInstruction, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2))),
                      ],
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
        ),
      ),
    );
  }

  Widget _buildExtraInfoRow(IconData icon, String title, String value, {bool showArrow = true}) {
    return Container(
      color: Colors.transparent,
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16))),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (showArrow) const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20) else const SizedBox(width: 20),
        ],
      ),
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

  Widget _buildActionButtons() {
    if (_trackingState == TrackingState.idle) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
          label: const Text('Start Tracking', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
          onPressed: _startTracking,
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _trackingState == TrackingState.active ? Colors.white.withOpacity(0.15) : Colors.white, foregroundColor: _trackingState == TrackingState.active ? Colors.white : Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            icon: Icon(_trackingState == TrackingState.active ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(_trackingState == TrackingState.active ? 'Pause' : 'Resume', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: _trackingState == TrackingState.active ? _pauseTracking : _resumeTracking,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF453A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            onPressed: _stopTracking,
          ),
        ),
      ],
    );
  }
}
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../providers/route_provider.dart';
import '../data/models/route_model.dart';

class RouteDetailsScreen extends StatefulWidget {
  final String routeId;

  const RouteDetailsScreen({super.key, required this.routeId});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final Dio _dio = Dio();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  String _weatherText = '...';
  bool _isWeatherFetched = false;

  // Данные карты
  List<LatLng> _points = [];
  bool _isLoadingMap = false;
  bool _mapError = false;

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final response = await _dio.get('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      if (response.statusCode == 200) {
        final current = response.data['current_weather'];
        if (mounted) {
          setState(() {
            _weatherText = '${current['temperature']}°C';
            _isWeatherFetched = true;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _weatherText = 'N/A');
    }
  }

  Future<void> _loadGpxData(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _mapError = true);
      return;
    }

    if (_points.isNotEmpty || _isLoadingMap) return;
    if (mounted) setState(() => _isLoadingMap = true);

    try {
      final response = await _dio.get(url);
      final xmlString = response.data.toString();

      if (xmlString.isNotEmpty) {
        // Ищем координаты строго внутри тегов <trkpt ... >
        final RegExp regExp = RegExp(r'<trkpt lat="([-+]?[\d.]+)" lon="([-+]?[\d.]+)"');
        final matches = regExp.allMatches(xmlString);

        List<LatLng> parsedPoints = [];
        for (var m in matches) {
          double lat = double.parse(m.group(1)!);
          double lon = double.parse(m.group(2)!);

          // Фильтруем битые координаты (0.0, 0.0), которые создают лишние линии
          if (lat != 0 && lon != 0) {
            parsedPoints.add(LatLng(lat, lon));
          }
        }

        if (parsedPoints.isEmpty) throw Exception("No points");

        if (mounted) {
          setState(() {
            _points = parsedPoints;
            _isLoadingMap = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMap = false;
          _mapError = true;
        });
      }
    }
  }

  Widget _buildMapMarker(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Icon(icon, color: Colors.white, size: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);
    final route = routeProvider.findById(widget.routeId);

    if (route == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Route not found', style: TextStyle(color: Colors.white))));

    if (!_isWeatherFetched) _fetchWeather(route.latitude, route.longitude);
    if (_points.isEmpty && !_mapError && !_isLoadingMap) _loadGpxData(route.gpxUrl);

    LatLngBounds? bounds;
    if (_points.length > 1) {
      bounds = LatLngBounds.fromPoints(_points);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: route.imageUrls.isNotEmpty
                      ? _buildTopGallery(context, route.imageUrls)
                      : Container(height: 400, color: Colors.white.withOpacity(0.05), child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 50)),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(route.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2))),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(route.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white54, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(route.location, style: const TextStyle(color: Colors.white54, fontSize: 16))),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(child: _buildInfoCard(Icons.route_rounded, 'Distance', route.calculatedDistance != null ? '${route.calculatedDistance!.toStringAsFixed(1)} km' : 'N/A')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInfoCard(Icons.terrain_rounded, 'Elevation', '${route.elevation.toInt()} m')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildInfoCard(Icons.timer_rounded, 'Est. Time', '4h 30m')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInfoCard(Icons.cloud_outlined, 'Weather', _weatherText)),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // --- МИНИ-КАРТА (СТАТИЧНАЯ И КЛИКАБЕЛЬНАЯ) ---
                        const Text('Route Map', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            // При нажатии переходим на основную карту и передаем название пика
                            context.push('/map?targetPeakName=${route.name}');
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
                              child: _buildMapContent(bounds),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        const Text('Description', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(route.description, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6)),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Кнопки Назад/Bookmark
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                    child: const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
            // Кнопка Старт
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black, Colors.black.withOpacity(0)]),
                ),
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF32D74B), foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () => context.go('/tracking'),
                    child: const Text('Start Hiking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Логика отрисовки карты: теперь без Spinner
  Widget _buildMapContent(LatLngBounds? bounds) {
    if (_mapError || _points.isEmpty) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, color: Colors.white24, size: 40),
          SizedBox(height: 8),
          Text('Map not available', style: TextStyle(color: Colors.white38)),
        ],
      );
    }
    return AbsorbPointer( // Делаем карту нечувствительной к жестам внутри контейнера
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: bounds != null ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(20), maxZoom: 16) : null,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Фиксируем карту
        ),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], userAgentPackageName: 'com.salamat.hiking_app'),
          PolylineLayer(polylines: [Polyline(points: _points, color: const Color(0xFF007AFF), strokeWidth: 5.0, strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round)]),
          MarkerLayer(markers: [
            Marker(point: _points.first, width: 30, height: 30, child: _buildMapMarker(const Color(0xFF32D74B), Icons.play_arrow_rounded)),
            Marker(point: _points.last, width: 30, height: 30, child: _buildMapMarker(Colors.redAccent, Icons.flag_rounded)),
          ]),
        ],
      ),
    );
  }

  Widget _buildTopGallery(BuildContext context, List<String> images) {
    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemCount: images.length,
            itemBuilder: (context, index) => Image.network(images[index], fit: BoxFit.cover),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8, height: 8,
                  decoration: BoxDecoration(color: _currentImageIndex == index ? const Color(0xFF32D74B) : Colors.white54, borderRadius: BorderRadius.circular(4)),
                )),
              ),
            ),
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black, Colors.transparent])))),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF32D74B), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
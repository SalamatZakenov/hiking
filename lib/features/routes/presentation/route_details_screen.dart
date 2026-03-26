// lib/features/routes/presentation/route_details_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class RouteDetailsScreen extends StatefulWidget {
  final String routeId;
  const RouteDetailsScreen({super.key, required this.routeId});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final Dio _dio = Dio();
  String _weatherText = '...';
  IconData _weatherIcon = Icons.cloud_outlined;

  late final Map<String, dynamic> peakData;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // Картинки убрали, оставили только текст и координаты
    final peaks = {
      'kok_tobe': {
        'title': 'Kok Tobe',
        'location': 'ALMATY, KAZAKHSTAN',
        'badge': 'EASY',
        'elevation': 1100,
        'desc': 'Кок-Тобе — гора в Алматы и популярная зона отдыха на вершине. Идеально подходит для легкой вечерней прогулки с панорамным видом на город и канатной дорогой.',
        'lat': 43.2328,
        'lng': 76.9727,
      },
      'shymbulak': {
        'title': 'Shymbulak',
        'location': 'ALMATY, KAZAKHSTAN',
        'badge': 'MIDDLE',
        'elevation': 2260,
        'desc': 'Шымбулак — крупнейший горнолыжный курорт в Центральной Азии. Расположен в живописном ущелье Заилийского Алатау. Отличное место для хайкинга летом.',
        'lat': 43.1283,
        'lng': 77.0806,
      },
      'bap': {
        'title': 'Big Almaty Peak',
        'location': 'ALMATY, KAZAKHSTAN',
        'badge': 'HARD',
        'elevation': 3680,
        'desc': 'Большой Алматинский Пик — величественная вершина в форме пирамиды. Подъем требует хорошей физической подготовки, но награждает невероятными видами на БАО.',
        'lat': 43.0601,
        'lng': 76.9333,
      }
    };

    peakData = peaks[widget.routeId] ?? peaks['kok_tobe']!;
    _fetchWeather(peakData['lat'], peakData['lng']);
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final response = await _dio.get('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      if (response.statusCode == 200) {
        final current = response.data['current_weather'];
        final int temp = current['temperature'].round();
        final int code = current['weathercode'];
        setState(() {
          _weatherText = '$temp°C';
          _weatherIcon = _getWeatherIcon(code);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Шапка с заглушкой вместо фото
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E), // Темный цвет шапки при скролле
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              // --- ВОТ НАША ЗАГЛУШКА ВМЕСТО КАРТИНКИ ИЗ ИНТЕРНЕТА ---
              background: Container(
                color: const Color(0xFF2C2C2E), // Классический темный Apple-цвет
                child: const Center(
                  child: Icon(
                    Icons.terrain_rounded,
                    size: 100,
                    color: Colors.white24, // Полупрозрачная белая иконка горы
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(peakData['title'], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black))),
                      _buildBadge(peakData['badge']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(peakData['location'], style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      _buildStatCard(Icons.height_rounded, '${peakData['elevation']}m', 'Elevation'),
                      const SizedBox(width: 16),
                      _buildStatCard(_weatherIcon, _weatherText, 'Weather'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 12),
                  Text(peakData['desc'], style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
                  const SizedBox(height: 32),

                  const Text('Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      final uniqueTarget = '${peakData['title']}||${DateTime.now().millisecondsSinceEpoch}';
                      context.go('/map', extra: peakData['title']);
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.grey[200]),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(peakData['lat'], peakData['lng']),
                              initialZoom: 13,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                            ),
                            children: [
                              TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'),
                              MarkerLayer(markers: [
                                Marker(point: LatLng(peakData['lat'], peakData['lng']), child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 40))
                              ])
                            ],
                          ),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Open in Full Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String diff) {
    Color c = diff == 'HARD' ? Colors.red : diff == 'EASY' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(diff, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStatCard(IconData icon, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.black87, size: 28),
            const SizedBox(height: 12),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
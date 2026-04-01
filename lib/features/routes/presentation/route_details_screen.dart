// lib/features/routes/presentation/route_details_screen.dart
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
import '../../../core/theme/app_theme.dart';

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
  bool _isWeatherFetched = false;

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

  void _openPhotoViewer(BuildContext context, String imageUrl, int routeId) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => RoutePhotoViewer(imageUrl: imageUrl, heroTag: 'photo_$routeId'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);

    RouteModel? route;
    try {
      route = routeProvider.routes.firstWhere((r) => r.id.toString() == widget.routeId);
    } catch (e) {
      route = null;
    }

    if (route != null && !_isWeatherFetched) {
      _isWeatherFetched = true;
      _fetchWeather(route.latitude, route.longitude);
    }

    if (route == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Route not found', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.go('/routes'), child: const Text('Go Back')),
              ],
            )
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Stack(
          children: [
            // --- 1. ЕДИНЫЙ СКРОЛЛИРУЕМЫЙ БЛОК ---
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Фотография маршрута
                  GestureDetector(
                    onTap: () => _openPhotoViewer(context, route!.imageUrl, route.id),
                    child: Hero(
                      tag: 'photo_${route.id}',
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.45,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                        ),
                        child: Image.network(
                          route.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.terrain_rounded, size: 80, color: Colors.white10)),
                        ),
                      ),
                    ),
                  ),

                  // Информация о маршруте
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(color: AppTheme.bgDark),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildBadge(route.category.toUpperCase(), Colors.blueAccent),
                            const SizedBox(width: 8),
                            _buildBadge(route.difficulty.toUpperCase(), _getDifficultyColor(route.difficulty)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Text(route.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppTheme.cardSlate, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(route.location, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500))),
                          ],
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            _buildStatCard(Icons.route_rounded, '${route.distance} km', 'Distance'),
                            const SizedBox(width: 16),
                            _buildStatCard(_weatherIcon, _weatherText, 'Weather'),
                          ],
                        ),
                        const SizedBox(height: 32),

                        const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        const Text(
                          'A beautiful trail that challenges your stamina but rewards you with breathtaking views. Make sure to bring enough water and wear proper hiking boots.',
                          style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 40),

                        // --- 3. ИСПРАВЛЕННЫЙ МАКЕТ КАРТЫ (ЕДИНАЯ КЛИКАБЕЛЬНАЯ ЗОНА) ---
                        GestureDetector(
                          onTap: () {
                            context.push('/map', extra: '${route!.name}||${route.latitude},${route.longitude}');
                          },
                          behavior: HitTestBehavior.opaque, // Клик срабатывает в любой точке этой области
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Route Map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Icon(Icons.open_in_full_rounded, color: Colors.white54, size: 20),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white10),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: IgnorePointer(
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCenter: LatLng(route.latitude, route.longitude),
                                        initialZoom: 13.0,
                                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                          retinaMode: true,
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: LatLng(route.latitude, route.longitude),
                                              width: 40, height: 40,
                                              child: const Icon(Icons.location_on, color: Color(0xFFFF453A), size: 40),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100), // Отступ внизу
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. ФИКСИРОВАННЫЕ ВЕРХНИЕ КНОПКИ ---
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassIconButton(Icons.arrow_back_ios_new_rounded, () {
                    if (context.canPop()) { context.pop(); } else { context.go('/routes'); }
                  }),
                  _buildGlassIconButton(Icons.favorite_border_rounded, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ПОМОЩНИКИ ---
  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toUpperCase()) {
      case 'HARD': return const Color(0xFFFF5252);
      case 'MEDIUM': return const Color(0xFFFF9F0A);
      case 'EASY': return const Color(0xFF4CAF50);
      default: return Colors.grey;
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
    );
  }

  Widget _buildStatCard(IconData icon, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.cardSlate, size: 28),
            const SizedBox(height: 12),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class RoutePhotoViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const RoutePhotoViewer({super.key, required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Hero(
            tag: '${heroTag}_appbar',
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Hero(
            tag: heroTag,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.terrain_rounded, size: 80, color: Colors.white10),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.white24));
              },
            ),
          ),
        ),
      ),
    );
  }
}